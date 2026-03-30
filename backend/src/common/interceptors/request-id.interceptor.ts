import { Injectable, NestInterceptor, ExecutionContext, CallHandler, Logger } from '@nestjs/common';
import { Observable, tap } from 'rxjs';
import { GqlExecutionContext } from '@nestjs/graphql';
import { randomUUID } from 'crypto';

@Injectable()
export class RequestIdInterceptor implements NestInterceptor {
  private readonly logger = new Logger('RequestTrace');

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const requestId = randomUUID();
    const startTime = Date.now();

    // Handle both HTTP and GraphQL contexts
    let request: any;
    let response: any;

    try {
      const gqlCtx = GqlExecutionContext.create(context);
      request = gqlCtx.getContext().req;
      response = gqlCtx.getContext().res;
    } catch {
      request = context.switchToHttp().getRequest();
      response = context.switchToHttp().getResponse();
    }

    if (request) {
      request.requestId = requestId;
    }

    if (response?.setHeader) {
      response.setHeader('X-Request-Id', requestId);
    }

    return next.handle().pipe(
      tap({
        next: () => {
          const duration = Date.now() - startTime;
          this.logger.log(JSON.stringify({
            requestId,
            method: request?.method,
            url: request?.url,
            duration,
            status: 'success',
          }));
        },
        error: (error) => {
          const duration = Date.now() - startTime;
          this.logger.error(JSON.stringify({
            requestId,
            method: request?.method,
            url: request?.url,
            duration,
            status: 'error',
            error: error?.message,
          }));
        },
      }),
    );
  }
}
