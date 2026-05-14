import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AgentService } from './agent.service';
import { AgentController } from './agent.controller';

@Module({
  imports: [ConfigModule],
  providers: [AgentService],
  controllers: [AgentController],
})
export class AgentModule {}
