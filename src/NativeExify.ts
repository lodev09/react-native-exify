import { TurboModuleRegistry, type TurboModule } from 'react-native';

export interface Spec extends TurboModule {
  read(uri: string): Promise<Object | null>;
  write(uri: string, tags: Object): Promise<Object>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('Exify');
