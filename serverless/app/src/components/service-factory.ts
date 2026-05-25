import { createAppService } from "./app-service";
import { dynamoHelloRepository } from "./dynamo-hello-repository";
import { wsBroadcaster } from "./ws-broadcaster";

export const appService = createAppService({
  helloRepository: dynamoHelloRepository,
  helloBroadcaster: wsBroadcaster
});
