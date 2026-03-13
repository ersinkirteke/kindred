import { InputType, Field } from '@nestjs/graphql';

/**
 * Input for analyzeReceiptText mutation
 * Contains OCR-extracted text from a receipt photo
 */
@InputType()
export class AnalyzeReceiptTextInput {
  @Field(() => String, { description: 'OCR-extracted receipt text' })
  text: string;
}
