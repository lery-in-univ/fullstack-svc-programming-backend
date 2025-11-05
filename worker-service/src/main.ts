import dotenv from "dotenv";

dotenv.config();

import { NestFactory } from "@nestjs/core";
import { AppModule } from "./app.module";
import { ConsoleLogger } from "@nestjs/common";

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(AppModule);

  const mainLogger = new ConsoleLogger("WorkerMain");
  mainLogger.log("워커 서비스가 정상적으로 시작되었습니다.");

  process.on("SIGTERM", async () => {
    console.log("SIGTERM signal을 받았습니다. 워커를 종료합니다.");
    await app.close();
  });
}

bootstrap();
