export interface AppIdentity {
  username: string;
  roles: Array<"admin" | "user">;
}

export interface HelloMessage {
  id: string;
  createdAt: string;
  message: string;
}

export interface AppHelloResponse {
  ok: true;
  service: "app";
  message: string;
  identity: AppIdentity;
  item?: HelloMessage;
}

export interface HelloRepository {
  putHello(input: { username: string; message: string }): Promise<HelloMessage>;
  getLatestHello(): Promise<HelloMessage | undefined>;
}

export interface HelloBroadcaster {
  broadcast(input: { username: string; message: string; createdAt: string }): Promise<void>;
}

export interface AppServiceDependencies {
  helloRepository: HelloRepository;
  helloBroadcaster: HelloBroadcaster;
}

export interface AppService {
  postHello(input: { identity: AppIdentity; message: string }): Promise<AppHelloResponse>;
  getLatest(input: { identity: AppIdentity }): Promise<AppHelloResponse>;
  getMe(input: { identity: AppIdentity }): Promise<{ ok: true; identity: AppIdentity }>;
  getAdmin(input: { identity: AppIdentity }): Promise<{ ok: true; panel: string; identity: AppIdentity }>;
}
