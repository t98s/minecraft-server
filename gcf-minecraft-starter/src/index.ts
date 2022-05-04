import { SlashCommandBuilder } from '@discordjs/builders'
import { REST } from '@discordjs/rest'
import compute from '@google-cloud/compute'
import functions from '@google-cloud/functions-framework'
import pubsub from '@google-cloud/pubsub'
import axios from 'axios'
import { Routes } from 'discord-api-types/v9'
import { InteractionResponseType, InteractionType, verifyKey } from 'discord-interactions'
import { parseEnv } from './env'
import { createLogger } from './logger'

const env = parseEnv(process.env)
const rest = new REST({
    version: '9',
}).setToken(env.DISCORD_APIKEY)
const topic = (new pubsub.PubSub()).topic(env.GCF_INVOKER_TOPIC)

const logger = createLogger()

async function init () {
    logger.info('start refreshing slash commands')
    await rest.put(
        Routes.applicationCommands(env.DISCORD_APPLICATION_ID),
        {
            body: [
                new SlashCommandBuilder().setName('startmc').setDescription('Start minecraft VM instance'),
            ],
        },
    )
}

init().catch(e => {
    logger.error(e)
    process.exit(1)
})

const catchPromiseError = (f: (req: functions.Request, res: functions.Response) => Promise<unknown>) =>
    async (req: functions.Request, res: functions.Response) => {
        try {
            await f(req, res)
        } catch (e) {
            logger.error(e)
            if (!res.headersSent) {
                res.status(500).send('internal error')
            }
        }
    }

functions.http('interaction', catchPromiseError(async (req, res) => {
    if (req.method !== 'POST') {
        return res.status(405).end('method not allowed')
    }

    if (!req.rawBody) {
        return res.status(422).end('body is empty')
    }

    const signature = req.get('X-Signature-Ed25519')
    const signatureTimestamp = req.get('X-Signature-Timestamp')

    if (!signature || !signatureTimestamp) {
        return res.status(401).end('invalid signature')
    }

    if (!verifyKey(
        req.rawBody,
        signature,
        signatureTimestamp,
        env.DISCORD_PUBLIC_KEY,
    )) {
        return res.status(401).end('invalid request signature')
    }
    logger.info('verify successful')
    logger.info(JSON.stringify(req.body, null, 4))

    switch (req.body.type) {
    case InteractionType.PING:
        logger.info('ping')

        return res.send({
            type: InteractionResponseType.PONG,
        })
    case InteractionType.APPLICATION_COMMAND:
        switch (req.body.data.name) {
        case 'startmc': {
            logger.info('startmc')

            // Cloud Functions はレスポンスを返した時点でそのあとの処理が実行される保証がなくなる
            // そのため別の関数に移譲する
            await topic.publishMessage({
                json: {
                    webhookUrl: `https://discord.com/api/webhooks/${env.DISCORD_APPLICATION_ID}/${req.body.token}`,
                },
            })
            res.send({
                type: InteractionResponseType.DEFERRED_CHANNEL_MESSAGE_WITH_SOURCE,
            })

            return
        }
        default:
            logger.info('unknown command received')

            return res.status(500).end('unknown command received')
        }
    default:
        logger.info('unknown request received')

        return res.status(500).end('unknown request received')
    }
}))

type StartInstanceInit = Omit<pubsub.protos.google.pubsub.v1.PubsubMessage, 'publishTime' | 'messageId'> & { data: string }

export async function startInstance ({ data }: StartInstanceInit) {
    const { webhookUrl } = JSON.parse(Buffer.from(data, 'base64').toString())
    const sendFollowUpMessage = (msg: string) => {
        logger.info(`sending follow up message: ${msg}`)

        return axios.post(webhookUrl, {
            content: msg,
        })
    }

    try {
        const instancesClient = new compute.InstancesClient()
        const operationsClient = new compute.ZoneOperationsClient()

        const targetInstance = {
            project: env.GCE_PROJECT_ID,
            zone: env.GCE_INSTANCE_ZONE,
            instance: env.GCE_INSTANCE_RESOURCE_ID,
        }

        logger.info('getting current status of instance')

        const [current] = await instancesClient.get(targetInstance)

        if (current.status !== 'TERMINATED') {
            await sendFollowUpMessage(`終了状態ではないため、起動を行いません (${current.status})`)

            return
        }

        logger.info('starting instance')

        const [response] = await instancesClient.start(targetInstance)
        const operation = response.latestResponse
        const [waitedOperation] = await operationsClient.wait({
            operation: operation.name,
            project: env.GCE_PROJECT_ID,
            zone: env.GCE_INSTANCE_ZONE,
        })

        if (waitedOperation.status === 'DONE') {
            if (waitedOperation.error?.errors) {
                const messages = waitedOperation.error.errors.map(e => e.message || e.code || 'unknown').join(', ')

                await sendFollowUpMessage(`起動しようとしましたが、エラーが発生しました (${messages})`)
            } else {
                await sendFollowUpMessage('起動しました')
            }
        } else {
            await sendFollowUpMessage('起動中です')
        }
    } catch (e) {
        await sendFollowUpMessage('内部エラーで失敗しました')
        logger.info(e)
    }
}
