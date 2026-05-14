import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ChatOllama } from '@langchain/community/chat_models/ollama';
import { AgentExecutor, createReactAgent } from 'langchain/agents';
import { DynamicTool } from '@langchain/core/tools';
import { PullRequestPromptTemplate } from 'langchain/prompts';
import { PromptTemplate } from '@langchain/core/prompts';
import { BaseMessage, HumanMessage, AIMessage, SystemMessage } from '@langchain/core/messages';
import axios from 'axios';

@Injectable()
export class AgentService {
  private readonly logger = new Logger(AgentService.name);
  private model: ChatOllama;
  private readonly apiUrl: string;

  constructor(private configService: ConfigService) {
    this.apiUrl = this.configService.get<string>('LARAVEL_API_URL', 'http://127.0.0.1:8000/api');
    
    this.model = new ChatOllama({
      baseUrl: 'http://localhost:11434',
      model: 'llama3',
      temperature: 0,
    });
  }

  private createTools(jwtToken: string) {
    const headers = {
      Authorization: jwtToken,
      Accept: 'application/json',
    };

    return [
      new DynamicTool({
        name: 'get_recently_watched',
        description: 'Get the most recently watched movie or episode by the user. Call this when the user asks to open or continue the movie they just watched.',
        func: async () => {
          try {
            const response = await axios.get(`${this.apiUrl}/watch-history`, { headers });
            if (response.data && response.data.length > 0) {
              const latest = response.data[0];
              return JSON.stringify({
                movieId: latest.movie_id,
                title: latest.movie?.title,
                position: latest.watched_seconds,
                duration: latest.duration_seconds
              });
            }
            return 'No recently watched movies found.';
          } catch (error) {
            this.logger.error('Error fetching recently watched:', error);
            return 'Failed to fetch watch history.';
          }
        },
      }),
      new DynamicTool({
        name: 'get_highest_rated',
        description: 'Get a list of the highest rated movies on the system. Call this when the user asks for highest rated or best movies.',
        func: async () => {
          try {
            const response = await axios.get(`${this.apiUrl}/movies?sort=rating_desc`, { headers });
            const movies = response.data.slice(0, 5).map(m => ({ id: m.id, title: m.title, rating: m.rating_avg }));
            return JSON.stringify(movies);
          } catch (error) {
            return 'Failed to fetch highest rated movies.';
          }
        },
      }),
      new DynamicTool({
        name: 'get_unwatched_movies',
        description: 'Get movies that the user has never watched. Call this when the user asks for movies they have not seen.',
        func: async () => {
          try {
            const response = await axios.get(`${this.apiUrl}/movies?unwatched=true`, { headers });
            const movies = response.data.slice(0, 5).map(m => ({ id: m.id, title: m.title }));
            return JSON.stringify(movies);
          } catch (error) {
            return 'Failed to fetch unwatched movies.';
          }
        },
      }),
      new DynamicTool({
        name: 'get_new_movies',
        description: 'Get newly added movies. Call this when the user asks for new movies.',
        func: async () => {
          try {
            const response = await axios.get(`${this.apiUrl}/movies`, { headers });
            const movies = response.data.slice(0, 5).map(m => ({ id: m.id, title: m.title }));
            return JSON.stringify(movies);
          } catch (error) {
            return 'Failed to fetch new movies.';
          }
        },
      }),
    ];
  }

  async processChat(text: string, history: { role: string, content: string }[], jwtToken: string) {
    const tools = this.createTools(jwtToken);
    
    const prompt = PromptTemplate.fromTemplate(`You are a helpful AI assistant for a movie application called TDMU Movie App.
Your goal is to answer the user's request and if they ask to open a specific movie, you should provide an action to open it.
You have access to tools to fetch movie data.
Always respond with a valid JSON object in the following format:
{{
  "text": "The conversational reply to the user (e.g. 'Đây là phim bạn mới xem: XYZ')",
  "action": "open_movie" | "none",
  "payload": {{
    "movieId": 123,
    "position": 120
  }}
}}
If no action is needed, set action to "none" and payload to null.
Respond in Vietnamese.

Available tools:
{tools}

Tool Names: {tool_names}

Use the following format for your thought process:
Question: the input question you must answer
Thought: you should always think about what to do
Action: the action to take, should be one of [{tool_names}]
Action Input: the input to the action
Observation: the result of the action
... (this Thought/Action/Action Input/Observation can repeat N times)
Thought: I now know the final answer
Final Answer: the final answer to the original input question (MUST be a valid JSON object)

Previous conversation history:
{chat_history}

Question: {input}
Thought:{agent_scratchpad}`);

    const agent = await createReactAgent({
      llm: this.model,
      tools,
      prompt,
    });

    const agentExecutor = new AgentExecutor({
      agent,
      tools,
      returnIntermediateSteps: false,
    });

    // Format history
    const formattedHistory = history.map(msg => 
      `${msg.role === 'user' ? 'Human' : 'AI'}: ${msg.content}`
    ).join('\n');

    try {
      const result = await agentExecutor.invoke({
        input: text,
        chat_history: formattedHistory,
      });

      // Attempt to parse JSON from the output
      let jsonStr = result.output;
      if (jsonStr.includes('\`\`\`json')) {
        jsonStr = jsonStr.split('\`\`\`json')[1].split('\`\`\`')[0].trim();
      } else if (jsonStr.includes('\`\`\`')) {
        jsonStr = jsonStr.split('\`\`\`')[1].split('\`\`\`')[0].trim();
      }

      const parsed = JSON.parse(jsonStr);
      return parsed;
    } catch (error) {
      this.logger.error('Error in agent execution:', error);
      return {
        text: 'Xin lỗi, tôi đã gặp lỗi khi xử lý yêu cầu của bạn.',
        action: 'none',
        payload: null
      };
    }
  }
}
