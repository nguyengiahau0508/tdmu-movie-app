import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ChatOllama } from '@langchain/ollama';
import { DynamicTool } from '@langchain/core/tools';
import { HumanMessage, AIMessage, SystemMessage } from '@langchain/core/messages';
import type { BaseMessage } from '@langchain/core/messages';
import axios from 'axios';

@Injectable()
export class AgentService {
  private readonly logger = new Logger(AgentService.name);
  private model: ChatOllama;
  private readonly apiUrl: string;

  constructor(private configService: ConfigService) {
    this.apiUrl = this.configService.get<string>('LARAVEL_API_URL', 'http://127.0.0.1:8000/api');

    this.model = new ChatOllama({
      baseUrl: this.configService.get<string>('OLLAMA_BASE_URL', 'http://localhost:11434'),
      model: this.configService.get<string>('OLLAMA_MODEL', 'gemma4:31b-cloud'),
      temperature: 0,
    });
  }

  private mapMovie(m: any) {
    return {
      id: m.id,
      title: m.title,
      slug: m.slug,
      description: m.description,
      poster_url: m.poster_url,
      backdrop_url: m.backdrop_url,
      release_year: m.release_year,
      country: m.country,
      duration: m.duration,
      type: m.type,
      rating_avg: m.rating_avg,
      rating_count: m.rating_count,
      is_published: m.is_published,
      created_at: m.created_at,
      updated_at: m.updated_at,
      genres: m.genres?.map((g: any) => ({ id: g.id, name: g.name, slug: g.slug })) ?? [],
    };
  }

  private mapEpisode(ep: any) {
    return {
      id: ep.id,
      movie_id: ep.movie_id,
      season_number: ep.season_number,
      episode_number: ep.episode_number,
      title: ep.title,
      description: ep.description,
      duration: ep.duration,
      video_url: ep.video_url,
      video_qualities: ep.video_qualities,
      thumbnail_url: ep.thumbnail_url,
      created_at: ep.created_at,
      updated_at: ep.updated_at,
    };
  }

  private mapWatchHistory(wh: any) {
    return {
      id: wh.id,
      user_id: wh.user_id,
      movie_id: wh.movie_id,
      episode_id: wh.episode_id,
      watched_seconds: wh.watched_seconds,
      duration_seconds: wh.duration_seconds,
      is_finished: wh.is_finished,
      updated_at: wh.updated_at,
      movie: wh.movie ? this.mapMovie(wh.movie) : null,
      episode: wh.episode ? this.mapEpisode(wh.episode) : null,
    };
  }

  private createTools(jwtToken: string): DynamicTool[] {
    const headers = {
      Authorization: jwtToken,
      Accept: 'application/json',
    };

    return [
      new DynamicTool({
        name: 'get_recently_watched',
        description:
          'Get the most recently watched movies/episodes by the user. Returns full watch history with movie and episode details.',
        func: async () => {
          try {
            const response = await axios.get(`${this.apiUrl}/watch-history`, { headers });
            if (response.data && response.data.length > 0) {
              const items = response.data.slice(0, 5).map((wh: any) => this.mapWatchHistory(wh));
              return JSON.stringify(items);
            }
            return JSON.stringify({ error: 'No recently watched movies found.' });
          } catch (error) {
            this.logger.error('Error fetching recently watched:', error);
            return JSON.stringify({ error: 'Failed to fetch watch history.' });
          }
        },
      }),
      new DynamicTool({
        name: 'get_highest_rated',
        description: 'Get the highest rated movies on the system, sorted by rating descending. Returns full movie details including genres.',
        func: async () => {
          try {
            const response = await axios.get(`${this.apiUrl}/movies?sort=rating_desc`, { headers });
            const movies = response.data.slice(0, 5).map((m: any) => this.mapMovie(m));
            return JSON.stringify(movies);
          } catch (error) {
            return JSON.stringify({ error: 'Failed to fetch highest rated movies.' });
          }
        },
      }),
      new DynamicTool({
        name: 'get_unwatched_movies',
        description: 'Get movies that the user has never watched before. Returns full movie details including genres.',
        func: async () => {
          try {
            const response = await axios.get(`${this.apiUrl}/movies?unwatched=true`, { headers });
            const movies = response.data.slice(0, 5).map((m: any) => this.mapMovie(m));
            return JSON.stringify(movies);
          } catch (error) {
            return JSON.stringify({ error: 'Failed to fetch unwatched movies.' });
          }
        },
      }),
      new DynamicTool({
        name: 'get_new_movies',
        description: 'Get newly added movies on the system, sorted by newest first. Returns full movie details including genres.',
        func: async () => {
          try {
            const response = await axios.get(`${this.apiUrl}/movies?sort=newest`, { headers });
            const movies = response.data.slice(0, 5).map((m: any) => this.mapMovie(m));
            return JSON.stringify(movies);
          } catch (error) {
            return JSON.stringify({ error: 'Failed to fetch new movies.' });
          }
        },
      }),
      new DynamicTool({
        name: 'get_movie_episodes',
        description: 'Search for a movie by name and get all its episodes with full details. Input should be the movie name or keyword to search for.',
        func: async (input: string) => {
          try {
            // Search for the movie by name
            const movieRes = await axios.get(`${this.apiUrl}/movies?q=${encodeURIComponent(input)}`, { headers });
            if (!movieRes.data || movieRes.data.length === 0) {
              return JSON.stringify({ error: `Không tìm thấy phim nào với từ khóa "${input}".` });
            }
            const movie = movieRes.data[0];

            // Fetch episodes for that movie
            const episodeRes = await axios.get(`${this.apiUrl}/episodes?movie_id=${movie.id}`, { headers });
            const episodes = episodeRes.data || [];

            return JSON.stringify({
              movie: this.mapMovie(movie),
              totalEpisodes: episodes.length,
              episodes: episodes.map((ep: any) => this.mapEpisode(ep)),
            });
          } catch (error) {
            return JSON.stringify({ error: 'Failed to fetch movie episodes.' });
          }
        },
      }),
    ];
  }

  async processChat(
    text: string,
    history: { role: string; content: string }[],
    jwtToken: string,
  ) {
    this.logger.log('════════════════════════════════════════════════');
    this.logger.log('🎤 [USER INPUT] ' + text);
    this.logger.log('📜 [HISTORY] ' + JSON.stringify(history.slice(-5), null, 2));

    const tools = this.createTools(jwtToken);

    // Build tool descriptions for the system prompt
    const toolDescriptions = tools
      .map((t) => `- ${t.name}: ${t.description}`)
      .join('\n');

    const systemPrompt = `You are a helpful AI assistant for a movie application called TDMU Movie App.
You can use the following tools to look up information. To call a tool, respond with EXACTLY:
TOOL_CALL: <tool_name> | <input>

If the tool does not need input, just write:
TOOL_CALL: <tool_name>

Available tools:
${toolDescriptions}

After you receive a tool result, analyze the data and give a final answer.

Your final answer MUST be a valid JSON object with exactly this structure (no markdown, no code fences):
{"text": "your reply in Vietnamese", "action": "open_movie or open_episode or none", "payload": {"movieId": 123, "episodeNumber": 1, "position": 0} or null}

If the user asks to continue/resume watching a movie they were watching (e.g. "mở tiếp phim tôi đang xem dở", "tiếp tục xem phim"), use get_recently_watched tool, then set action to "open_episode" and include movieId, episodeNumber (from episode data), and position (from watched_seconds) in payload. Tell the user what movie and what time position they will resume from.
If the user asks to open a recently watched movie, set action to "open_movie" and include the movieId and position from the tool result.
If the user asks to open a specific episode of a movie (e.g. "mở phim X tập 3"), use get_movie_episodes tool first to find the movie, then set action to "open_episode" and include movieId and episodeNumber in payload. Set position to 0.
If no specific action is needed, set action to "none" and payload to null.
Always respond in Vietnamese.`;

    // Build message history
    const messages: BaseMessage[] = [new SystemMessage(systemPrompt)];

    for (const msg of history.slice(-5)) {
      if (msg.role === 'user') {
        messages.push(new HumanMessage(msg.content));
      } else {
        messages.push(new AIMessage(msg.content));
      }
    }

    messages.push(new HumanMessage(text));

    try {
      // First call: let the model decide whether to call a tool
      this.logger.log('🤖 [OLLAMA] Sending first request to model...');
      let response = await this.model.invoke(messages);
      let content = typeof response.content === 'string' ? response.content : '';
      this.logger.log('🤖 [OLLAMA RESPONSE #1]\n' + content);

      // Check if the model wants to call a tool
      const toolCallMatch = content.match(/TOOL_CALL:\s*(\S+)(?:\s*\|\s*(.+))?/);
      if (toolCallMatch) {
        const toolName = toolCallMatch[1].trim();
        const toolInput = (toolCallMatch[2] || '').trim();
        const tool = tools.find((t) => t.name === toolName);

        if (tool) {
          this.logger.log(`🔧 [TOOL CALL] Calling tool: ${toolName}, input: "${toolInput}"`);
          const toolResult = await tool.invoke(toolInput);
          this.logger.log(`🔧 [TOOL RESULT] ${toolName} returned:\n${toolResult}`);

          // Add the tool interaction to messages and call the model again
          messages.push(new AIMessage(content));
          messages.push(
            new HumanMessage(`Tool "${toolName}" returned:\n${toolResult}\n\nNow provide your final JSON answer based on this data.`),
          );

          this.logger.log('🤖 [OLLAMA] Sending second request with tool result...');
          response = await this.model.invoke(messages);
          content = typeof response.content === 'string' ? response.content : '';
          this.logger.log('🤖 [OLLAMA RESPONSE #2]\n' + content);
        } else {
          this.logger.warn(`⚠️ [TOOL NOT FOUND] Model requested unknown tool: ${toolName}`);
        }
      } else {
        this.logger.log('ℹ️ [NO TOOL CALL] Model answered directly without calling a tool.');
      }

      // Parse the JSON response
      const parsed = this.parseAgentResponse(content);
      this.logger.log('✅ [FINAL RESPONSE] ' + JSON.stringify(parsed, null, 2));
      this.logger.log('════════════════════════════════════════════════');
      return parsed;
    } catch (error) {
      this.logger.error('❌ [ERROR] Agent execution failed:', error);
      this.logger.log('════════════════════════════════════════════════');
      return {
        text: 'Xin lỗi, tôi đã gặp lỗi khi xử lý yêu cầu của bạn.',
        action: 'none',
        payload: null,
      };
    }
  }

  private parseAgentResponse(content: string) {
    try {
      // Try to extract JSON from the response
      let jsonStr = content;

      // Remove markdown code fences if present
      const jsonMatch = content.match(/```(?:json)?\s*([\s\S]*?)```/);
      if (jsonMatch) {
        jsonStr = jsonMatch[1].trim();
      }

      // Try to find a JSON object in the string
      const objectMatch = jsonStr.match(/\{[\s\S]*\}/);
      if (objectMatch) {
        jsonStr = objectMatch[0];
      }

      const parsed = JSON.parse(jsonStr);
      return {
        text: parsed.text || content,
        action: parsed.action || 'none',
        payload: parsed.payload || null,
      };
    } catch {
      // If JSON parsing fails, return the raw text
      return {
        text: content,
        action: 'none',
        payload: null,
      };
    }
  }
}
