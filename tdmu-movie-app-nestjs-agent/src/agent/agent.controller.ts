import { Controller, Post, Body, Headers, BadRequestException } from '@nestjs/common';
import { AgentService } from './agent.service';

interface ChatRequest {
  text: string;
  history: { role: string; content: string }[];
}

@Controller('agent')
export class AgentController {
  constructor(private readonly agentService: AgentService) {}

  @Post('chat')
  async chat(@Body() body: ChatRequest, @Headers('authorization') authHeader: string) {
    if (!body.text) {
      throw new BadRequestException('Text is required');
    }

    const jwtToken = authHeader || '';

    const response = await this.agentService.processChat(body.text, body.history || [], jwtToken);
    
    return response;
  }
}
