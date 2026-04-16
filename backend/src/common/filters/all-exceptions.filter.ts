import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { GqlArgumentsHost } from '@nestjs/graphql';
import { GraphQLError } from 'graphql';

@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger(AllExceptionsFilter.name);

  catch(exception: unknown, host: ArgumentsHost) {
    const timestamp = new Date().toISOString();

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let message = 'Internal server error';

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const response = exception.getResponse();
      message = typeof response === 'string' ? response : (response as any).message;
    } else if (exception instanceof Error) {
      // Don't expose raw error messages to clients (may leak DB details, file paths)
      message = 'Internal server error';
    }

    // Determine if this is a REST or GraphQL request
    const hostType = host.getType<string>();

    if (hostType === 'http') {
      // REST request — return JSON response directly
      const ctx = host.switchToHttp();
      const response = ctx.getResponse();
      const request = ctx.getRequest();
      const path = request?.url || '/';

      this.logger.error({
        timestamp,
        path,
        statusCode: status,
        message,
        stack: exception instanceof Error ? exception.stack : undefined,
      });

      response.status(status).json({
        statusCode: status,
        message,
        timestamp,
      });
      return;
    }

    // GraphQL request
    const gqlHost = GqlArgumentsHost.create(host);
    const ctx = gqlHost.getContext();
    const path = ctx?.req?.url || 'graphql';

    this.logger.error({
      timestamp,
      path,
      statusCode: status,
      message,
      stack: exception instanceof Error ? exception.stack : undefined,
    });

    throw new GraphQLError(message, {
      extensions: {
        code: this.getErrorCode(status),
        statusCode: status,
        timestamp,
      },
    });
  }

  private getErrorCode(status: number): string {
    switch (status) {
      case HttpStatus.BAD_REQUEST:
        return 'BAD_REQUEST';
      case HttpStatus.UNAUTHORIZED:
        return 'UNAUTHORIZED';
      case HttpStatus.FORBIDDEN:
        return 'FORBIDDEN';
      case HttpStatus.NOT_FOUND:
        return 'NOT_FOUND';
      case HttpStatus.TOO_MANY_REQUESTS:
        return 'TOO_MANY_REQUESTS';
      default:
        return 'INTERNAL_SERVER_ERROR';
    }
  }
}
