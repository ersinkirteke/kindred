import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AppModule } from './app.module';
import { AllExceptionsFilter } from './common/filters/all-exceptions.filter';

async function bootstrap() {
  const logger = new Logger('Bootstrap');

  const app = await NestFactory.create(AppModule);
  const configService = app.get(ConfigService);

  // Enable CORS for mobile clients
  app.enableCors({
    origin:
      configService.get('NODE_ENV') === 'production'
        ? ['https://kindred.app'] // Restrict in production
        : true, // Allow all origins in development
    credentials: true,
  });

  // Set body parser limit for future voice upload proxy
  app.use(require('express').json({ limit: '10mb' }));
  app.use(require('express').urlencoded({ limit: '10mb', extended: true }));

  // Global validation pipe
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  // Global exception filter for GraphQL-friendly errors
  app.useGlobalFilters(new AllExceptionsFilter());

  // Get port from config
  const port = configService.get('PORT', 3000);

  await app.listen(port);

  logger.log(`🚀 NestJS application started`);
  logger.log(`📍 GraphQL Playground: http://localhost:${port}/v1/graphql`);
  logger.log(`🏥 Health check: http://localhost:${port}/v1/graphql (query { health })`);
  logger.log(
    `🌍 Environment: ${configService.get('NODE_ENV', 'development')}`,
  );
}

bootstrap();
