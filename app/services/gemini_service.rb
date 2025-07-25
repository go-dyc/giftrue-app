# frozen_string_literal: true

class GeminiService
  class << self
    def generate_plaque_content(title: "", name: "", style: "gold_metal", relationship: "", purpose: "", tone: "formal", special_note: "")
      return "API 키가 설정되지 않았습니다." unless api_key.present?
      
      begin
        prompt = build_prompt(
          title: title, 
          name: name, 
          style: style,
          relationship: relationship,
          purpose: purpose,
          tone: tone,
          special_note: special_note
        )
        
        # Gemini API 호출
        client = Gemini.new(
          credentials: {
            service: 'generative-language-api',
            api_key: api_key
          },
          options: { model: 'gemini-1.5-flash', server_sent_events: false }
        )

        result = client.stream_generate_content({
          contents: {
            role: 'user',
            parts: { text: prompt }
          },
          generationConfig: {
            temperature: 0.8,
            topK: 40,
            topP: 0.9,
            maxOutputTokens: 400,
            stopSequences: []
          }
        })

        # 응답에서 텍스트 추출
        generated_text = extract_text_from_response(result)
        
        # 자연스러운 줄바꿈 적용 (12자씩)
        formatted_text = format_with_line_breaks(generated_text)
        
        # 길이 제한 적용 (완전한 문장으로)
        truncate_to_complete_sentence(formatted_text, 90)
        
      rescue => e
        Rails.logger.error "Gemini API 호출 실패: #{e.message}"
        "죄송합니다. 문구 생성 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요."
      end
    end

    private

    def api_key
      ENV.fetch('GEMINI_API_KEY', nil)
    end

    def build_prompt(title:, name:, style:, relationship: "", purpose: "", tone: "formal", special_note: "")
      context_parts = []
      context_parts << title if title.present?
      context_parts << "#{name}님" if name.present?
      context_parts << relationship if relationship.present?
      context_parts << purpose if purpose.present?
      context_parts << special_note if special_note.present?
      
      situation = context_parts.any? ? context_parts.join(', ') + "를 위한 기념패" : "기념패"
      style_guide = tone.present? ? "#{tone} 스타일로" : "마음을 담아"
      
      <<~PROMPT
        #{situation} 문구를 #{style_guide} 작성해주세요.
        
        기념패 문구의 핵심 원칙:
        - 70-90자 내외의 적당한 분량 (5-7줄 구성)
        - 편지가 아닌 기념패 특성에 맞는 함축적 표현
        - 반드시 완전한 문장으로만 구성 (마침표/느낌표로 완결)
        
        구성 패턴 (3-4단계):
        1. 대상자 호명: "송민수 부장님" 또는 "[이름]님"
        2. 핵심 감사/축하: "[기간/상황] 진심으로 감사드립니다"
        3. 구체적 공로/특징: "따뜻한 리더십과 헌신적인 노고"
        4. 미래 축원: "건강하고 행복한 [미래상황] 기원합니다"
        
        표현 지침:
        - 직설적이고 명확한 존댓말 ("~드립니다", "~합니다")
        - 수식어 최소화, 핵심 키워드 중심
        - 쉼표(,) 대신 마침표로 문장 분리
        - 관계별 적절한 표현 (부하→상사: 존경/감사, 상사→부하: 격려/축복)
        
        참고 예시:
        "송민수 부장님께. 20년간 성실한 근무 진심으로 감사드립니다. 따뜻한 리더십과 헌신적인 노고 깊이 존경합니다. 건강하고 행복한 제2의 인생 기원합니다."
      PROMPT
    end

    def extract_text_from_response(result)
      # 스트림 응답에서 텍스트 추출
      text_parts = []
      
      result.each do |chunk|
        if chunk.dig('candidates', 0, 'content', 'parts')
          chunk['candidates'][0]['content']['parts'].each do |part|
            text_parts << part['text'] if part['text']
          end
        end
      end
      
      text_parts.join('').strip
    end

    # 간단하고 자연스러운 줄바꿈 적용
    def format_with_line_breaks(text)
      # 기존 줄바꿈 제거하고 공백 정리
      clean_text = text.gsub(/\s+/, ' ').strip
      
      # 문장별로 먼저 분리 (마침표, 느낌표 기준)
      sentences = clean_text.split(/(?<=[.!?])\s+/).map(&:strip).reject(&:empty?)
      
      # 각 문장을 한 줄로 처리 (길면 적절히 분할)
      lines = []
      
      sentences.each do |sentence|
        if sentence.length <= 15
          # 짧은 문장은 그대로 한 줄
          lines << sentence
        else
          # 긴 문장은 의미단위로 분할
          words = sentence.split(' ')
          current_line = ""
          
          words.each do |word|
            test_line = current_line.empty? ? word : "#{current_line} #{word}"
            
            if test_line.length <= 15
              current_line = test_line
            else
              # 현재 줄을 저장하고 새 줄 시작
              lines << current_line unless current_line.empty?
              current_line = word
            end
          end
          
          # 마지막 줄 추가
          lines << current_line unless current_line.empty?
        end
      end
      
      lines.join("\n")
    end
    
    # 완전한 문장으로 자르기 (개선)
    def truncate_to_complete_sentence(text, limit)
      return text if text.length <= limit
      
      # 문장 단위로 분리 (마침표, 느낌표, 물음표 기준)
      sentences = text.split(/(?<=[.!?])\s*/)
      result = ""
      
      sentences.each do |sentence|
        sentence = sentence.strip
        next if sentence.empty?
        
        # 현재 결과에 이 문장을 추가했을 때의 길이
        test_result = result.empty? ? sentence : "#{result}\n#{sentence}"
        
        if test_result.length <= limit
          result = test_result
        else
          # 제한을 초과하면 여기서 중단
          break
        end
      end
      
      # 결과가 비어있거나 문장부호로 끝나지 않으면 처리
      if result.empty?
        # 첫 문장도 너무 길면 적절히 자르고 마침표 추가
        first_sentence = sentences.first&.strip || ""
        if first_sentence.length > limit
          truncated = first_sentence[0, limit - 1]
          last_space = truncated.rindex(' ')
          if last_space && last_space > limit * 0.7
            result = truncated[0, last_space] + "."
          else
            result = truncated + "."
          end
        else
          result = first_sentence
        end
      end
      
      # 마지막이 문장부호가 아니면 마침표 추가
      unless result =~ /[.!?]$/
        result += "."
      end
      
      result.strip
    end
  end
end