// @ts-check

const functions = require('@google-cloud/functions-framework')
const { z } = require('zod')
const { SlashCommandBuilder } = require('@discordjs/builders')
const { REST } = require('@discordjs/rest')
const { Routes } = require('discord-api-types/v9')
const { verifyKey, InteractionType, InteractionResponseType } = require('discord-interactions')
const compute = require('@google-cloud/compute')
const axios = require('axios').default
const util = require('util')
const pubsub = require('@google-cloud/pubsub')

const parseEnv = () => z.object({
    DISCORD_APPLICATION_ID: z.string(),
    DISCORD_APIKEY: z.string(),
    DISCORD_PUBLIC_KEY: z.string(),
    GCE_PROJECT_ID: z.string(),
    GCE_INSTANCE_RESOURCE_ID: z.string(),
    GCE_INSTANCE_ZONE: z.string(),
    GCF_INVOKER_TOPIC: z.string(),
}).parse(process.env)

const env = parseEnv()
const rest = new REST({ version: '9' }).setToken(env.DISCORD_APIKEY)
const topic = (new pubsub.PubSub()).topic(env.GCF_INVOKER_TOPIC)

async function init() {
    console.log('start refreshing slash commands')
    await rest.put(
        Routes.applicationCommands(env.DISCORD_APPLICATION_ID),
        {
            body: [
                new SlashCommandBuilder().setName("startmc").setDescription("Start minecraft VM instance")
            ]
        }
    )
}

init().catch(e => {
    console.error(e)
    process.exit(1)
})

/**
 * @param {(req: functions.Request, res: functions.Response) => Promise<unknown>} f
 */
const catchPromiseError = f =>
    /**
     * @param {functions.Request} req
     * @param {functions.Response} res 
     */
    async (req, res) => {
        try {
            await f(req, res)
        } catch (e) {
            log(e, "ERROR")
            if (!res.headersSent) {
                res.status(500).send("internal error")
            }
        }
    }

/**
 * @param {string|object} message
 * @param {"DEBUG"|"ERROR"} serverity
 */
const log = (message, serverity = "DEBUG") => {
    console.log(JSON.stringify({
        serverity,
        message: typeof message === "string" ? message : util.inspect(message),
    }))
}

functions.http('interaction', catchPromiseError(async (req, res) => {
    if (req.method !== "POST") {
        return res.status(405).end('method not allowed')
    }

    if (!verifyKey(
        req.rawBody,
        req.get('X-Signature-Ed25519'),
        req.get('X-Signature-Timestamp'),
        env.DISCORD_PUBLIC_KEY
    )) {
        return res.status(401).end('invalid request signature')
    }
    log('verify successful')
    log(JSON.stringify(req.body, null, 4))

    switch (req.body["type"]) {
        case InteractionType.PING:
            log('ping')
            return res.send({ "type": InteractionResponseType.PONG })
        case InteractionType.APPLICATION_COMMAND:
            switch (req.body.data.name) {
                case "startmc": {
                    log('startmc')

                    // Cloud Functions はレスポンスを返した時点でそのあとの処理が実行される保証がなくなる
                    // そのため別の関数に移譲する
                    await topic.publishMessage({
                        json: {
                            webhookUrl: `https://discord.com/api/webhooks/${env.DISCORD_APPLICATION_ID}/${req.body.token}`,
                        }
                    })
                    res.send({
                        "type": InteractionResponseType.DEFERRED_CHANNEL_MESSAGE_WITH_SOURCE,
                    })
                    return
                }
                default:
                    log("unknown command received")
                    return res.status(500).end("unknown command received")
            }
        default:
            log("unknown request received")
            return res.status(500).end("unknown request received")
    }
}))

/**
 * @param {Omit<pubsub.protos.google.pubsub.v1.PubsubMessage, 'publishTime' | 'messageId'> & { data: string }} message
 */
exports.startInstance = async (message) => {
    const { webhookUrl } = JSON.parse(Buffer.from(message.data, 'base64').toString())
    const sendFollowUpMessage = (msg) => {
        log(`sending follow up message: ${msg}`)
        return axios.post(webhookUrl, {
            content: msg
        })
    }
    try {
        const instancesClient = new compute.InstancesClient()
        const operationsClient = new compute.ZoneOperationsClient()

        const targetInstance = {
            project: env.GCE_PROJECT_ID,
            zone: env.GCE_INSTANCE_ZONE,
            instance: env.GCE_INSTANCE_RESOURCE_ID
        }
        log("getting current status of instance")
        const [current] = await instancesClient.get(targetInstance)
        if (current.status != "TERMINATED") {
            await sendFollowUpMessage(`終了状態ではないため、起動を行いません (${current.status})`)
            return
        }
        log("starting instance")
        const [response] = await instancesClient.start(targetInstance)
        let operation = response.latestResponse
        const [waited_operation] = await operationsClient.wait({
            operation: operation.name,
            project: env.GCE_PROJECT_ID,
            zone: env.GCE_INSTANCE_ZONE,
        })

        let message = waited_operation.status === "DONE" ? "起動しました" : "起動中です"
        if (waited_operation.status === "DONE" && waited_operation.error) {
            const msgs = waited_operation.error.errors.map(e => e.message || e.code || "unknown").join(", ")
            message = `起動しようとしましたが、エラーが発生しました (${msgs})`
        }
        await sendFollowUpMessage(message)
    } catch (e) {
        await sendFollowUpMessage("内部エラーで失敗しました")
        log(e, "ERROR")
    }
}
