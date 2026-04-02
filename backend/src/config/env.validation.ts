import { IsString, IsNotEmpty, IsEnum, IsOptional, IsInt, validateSync } from 'class-validator';
import { plainToInstance, Transform } from 'class-transformer';

enum NodeEnv {
  Development = 'development',
  Staging = 'staging',
  Production = 'production',
}

export class EnvironmentVariables {
  // Database
  @IsString()
  @IsNotEmpty()
  DATABASE_URL: string;

  // Server
  @IsEnum(NodeEnv)
  @IsNotEmpty()
  NODE_ENV: NodeEnv = NodeEnv.Development;

  @Transform(({ value }) => parseInt(value, 10))
  @IsInt()
  PORT: number = 3000;

  // Authentication - Clerk (optional for local dev, validated at service level)
  @IsString()
  @IsOptional()
  CLERK_SECRET_KEY?: string;

  @IsString()
  @IsOptional()
  CLERK_PUBLISHABLE_KEY?: string;

  // Cloudflare R2 Storage (optional for local dev)
  @IsString()
  @IsOptional()
  R2_ACCESS_KEY_ID?: string;

  @IsString()
  @IsOptional()
  R2_SECRET_ACCESS_KEY?: string;

  @IsString()
  @IsOptional()
  CLOUDFLARE_ACCOUNT_ID?: string;

  // Google Cloud AI Services (optional for local dev)
  @IsString()
  @IsOptional()
  GOOGLE_CLOUD_PROJECT?: string;

  @IsString()
  @IsOptional()
  FIREBASE_SERVICE_ACCOUNT_PATH?: string;
}

export function validate(config: Record<string, unknown>) {
  const validatedConfig = plainToInstance(EnvironmentVariables, config, {
    enableImplicitConversion: true,
  });
  const errors = validateSync(validatedConfig, { skipMissingProperties: false });
  if (errors.length > 0) {
    throw new Error(`Environment validation failed:\n${errors.toString()}`);
  }
  return validatedConfig;
}
