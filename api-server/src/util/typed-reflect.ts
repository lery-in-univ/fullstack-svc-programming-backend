export class TypedReflect {
  static getMetadata<T>(metadataKey: any, target: object): T | undefined {
    return Reflect.getMetadata(metadataKey, target) as T | undefined;
  }
}
