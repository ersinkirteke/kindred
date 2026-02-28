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
    const gqlHost = GqlArgumentsHost.create(host);
    const ctx = gqlHost.getContext();

    const timestamp = new Date().toISOString();
    const path = ctx?.req?.url || 'graphql';

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let message = 'Internal server error';

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const response = exception.getResponse();
      message = typeof response === 'string' ? response : (response as any).message;
    } else if (exception instanceof Error) {
      message = exception.message;
    }

    // Log the error with structured format
    this.logger.error({
      timestamp,
      path,
      statusCode: status,
      message,
      stack: exception instanceof Error ? exception.stack : undefined,
    });

    // Return GraphQL-friendly error
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
