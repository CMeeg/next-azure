import 'server-only'

const environment = {
  development: 'development',
  production: 'production'
} as const

type Environment = keyof typeof environment

const environmentAlias: Array<{ environment: Environment; aliases: string[] }> =
  [
    {
      environment: environment.development,
      aliases: [environment.development, 'dev']
    },
    {
      environment: environment.production,
      aliases: [environment.production, 'prod']
    }
  ]

const appEnvironment =
  process.env.APP_ENV ||
  process.env.NODE_ENV ||
  (environment.development satisfies Environment)

const currentEnvironment = environmentAlias.reduce<Environment>(
  (currentEnv, envAlias) => {
    if (envAlias.aliases.includes(appEnvironment)) {
      currentEnv = envAlias.environment
    }

    return currentEnv
  },
  environment.development
)

export { environment, currentEnvironment }

export type { Environment }
