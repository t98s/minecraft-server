/* eslint-disable no-console */
import util from 'util'

export type LogSeverity = 'DEBUG' | 'ERROR' | 'INFO'

export interface Logger {
  log (serverity: LogSeverity, message: string | unknown): void;
  info (message: string | unknown): void;
  error (message: string | unknown): void;
  debug (message: string | unknown): void;
}

export function createLogger (): Logger {
    const logger: Logger = {
        log (serverity, message) {
            console.log(JSON.stringify({
                serverity,
                message: typeof message === 'string' ? message : util.inspect(message),
            }))
        },
        error (message) {
            logger.log('ERROR', message)
        },
        info (message) {
            logger.log('INFO', message)
        },
        debug (message) {
            logger.log('DEBUG', message)
        },
    }

    return logger
}
