import { z } from 'zod'

const envSchema = z.object({
    DISCORD_APPLICATION_ID: z.string(),
    DISCORD_APIKEY: z.string(),
    DISCORD_PUBLIC_KEY: z.string(),
    GCE_PROJECT_ID: z.string(),
    GCE_INSTANCE_RESOURCE_ID: z.string(),
    GCE_INSTANCE_ZONE: z.string(),
    GCF_INVOKER_TOPIC: z.string(),
})

type AppEnv = z.infer<typeof envSchema>

export function parseEnv (env: NodeJS.ProcessEnv): AppEnv {
    return envSchema.parse(env)
}
