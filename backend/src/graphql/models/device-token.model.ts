import { ObjectType, Field, ID, registerEnumType } from '@nestjs/graphql';

export enum Platform {
  IOS = 'IOS',
  ANDROID = 'ANDROID',
}

registerEnumType(Platform, {
  name: 'Platform',
  description: 'Mobile platform for push notifications',
});

@ObjectType()
export class DeviceToken {
  @Field(() => ID)
  id: string;

  @Field(() => Platform)
  platform: Platform;

  @Field()
  createdAt: Date;
}
