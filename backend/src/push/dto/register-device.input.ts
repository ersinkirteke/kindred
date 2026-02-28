import { InputType, Field } from '@nestjs/graphql';
import { IsString, IsEnum, IsNotEmpty, IsOptional } from 'class-validator';
import { GraphQLJSONObject } from 'graphql-type-json';
import { Platform } from '../../graphql/models/device-token.model';

@InputType()
export class RegisterDeviceInput {
  @Field()
  @IsString()
  @IsNotEmpty()
  token: string;

  @Field(() => Platform)
  @IsEnum(Platform)
  platform: Platform;
}

@InputType()
export class SendNotificationInput {
  @Field()
  @IsString()
  @IsNotEmpty()
  userId: string;

  @Field()
  @IsString()
  @IsNotEmpty()
  title: string;

  @Field()
  @IsString()
  @IsNotEmpty()
  body: string;

  @Field(() => GraphQLJSONObject, { nullable: true })
  @IsOptional()
  data?: Record<string, string>;
}
