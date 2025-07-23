# frozen_string_literal: true

class GeminiService
  class << self
    def generate_plaque_content(title: "", name: "", style: "gold_metal", relationship: "", purpose: "", tone: "formal", special_note: "")
      return "API 키가 설정되지 않았습니다." unless api_key.present?
      
      begin
        # 금속패 스타일에 따른 문구 생성 (맥락 정보 포함)
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
            temperature: 0.7,
            topK: 40,
            topP: 0.8,
            maxOutputTokens: 200,
            stopSequences: []
          }
        })

        # 응답에서 텍스트 추출
        generated_text = extract_text_from_response(result)
        
        # 150자 제한 적용
        truncate_to_limit(generated_text, 150)
        
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
      # 기본 정보 구성
      context_parts = []
      context_parts << "제목: #{title}" if title.present?
      context_parts << "성함: #{name}" if name.present?
      
      # 맥락 정보 구성
      context_parts << "관계: #{get_relationship_description(relationship)}" if relationship.present?
      context_parts << "목적: #{get_purpose_description(purpose)}" if purpose.present?
      context_parts << "톤: #{get_tone_description(tone)}" if tone.present?
      context_parts << "특징: #{special_note}" if special_note.present?
      
      context_info = context_parts.any? ? context_parts.join(" | ") : "기념패"
      
      # 맥락에 따른 맞춤형 템플릿 선택
      template = get_enhanced_template(title, relationship, purpose, tone, special_note, name)
      
      prompt = <<~PROMPT
        당신은 한국어 기념패 문구 전문 작가입니다. 주어진 맥락 정보를 바탕으로 최적화된 기념패 문구를 작성해주세요.

        【맥락 정보】
        #{context_info}

        【작성 규칙】
        ✅ 문자 수: 정확히 100-150자 (공백 포함)
        ✅ 문체: #{get_tone_guide(tone)}
        ✅ 감정: 감사, 축하, 격려의 의미 포함
        ✅ 구성: 도입 → 본문 → 마무리 순서
        ✅ 출력: 문구만 작성 (설명, 따옴표, 부가설명 금지)

        #{template}

        【금지사항】
        ❌ 설명문, 해석, 부가설명 금지
        ❌ 따옴표("", '') 사용 금지  
        ❌ 150자 초과 또는 100자 미만 금지
        ❌ 구어체, 반말 사용 금지

        위 맥락과 조건을 모두 고려하여 완벽한 기념패 문구를 작성하세요:
      PROMPT
    end

    # 관계 설명 변환
    def get_relationship_description(relationship)
      case relationship
      when 'superior_to_subordinate' then '상사가 부하직원에게'
      when 'colleague_to_colleague' then '동료가 동료에게'
      when 'subordinate_to_superior' then '부하직원이 상사에게'
      when 'family_to_family' then '가족이 가족에게'
      when 'friend_to_friend' then '친구가 친구에게'
      when 'organization_to_individual' then '기관이 개인에게'
      else ''
      end
    end

    # 목적 설명 변환
    def get_purpose_description(purpose)
      case purpose
      when 'retirement' then '퇴직/전역 축하'
      when 'promotion' then '승진/임명 축하'
      when 'graduation' then '졸업/수료 축하'
      when 'award' then '수상/표창 축하'
      when 'appreciation' then '감사 표현'
      when 'anniversary' then '기념일 축하'
      else ''
      end
    end

    # 톤 설명 변환
    def get_tone_description(tone)
      case tone
      when 'formal' then '격식있고 공식적'
      when 'warm' then '따뜻하고 인간적'
      when 'concise' then '간결하고 깔끔'
      else '격식있고 공식적'
      end
    end

    # 톤 가이드라인
    def get_tone_guide(tone)
      case tone
      when 'formal' then '매우 정중하고 격식있는 존댓말 (공식 문서 수준)'
      when 'warm' then '정중하되 따뜻하고 친근한 존댓말 (인간적 감정 표현)'
      when 'concise' then '정중하고 간결한 존댓말 (핵심만 전달)'
      else '매우 정중하고 격식있는 존댓말'
      end
    end

    # 맥락 강화 템플릿 선택
    def get_enhanced_template(title, relationship, purpose, tone, special_note, name)
      # 목적 우선 템플릿 선택
      primary_purpose = purpose.present? ? purpose : get_purpose_from_title(title)
      
      case primary_purpose
      when 'retirement'
        get_retirement_template(relationship, tone, special_note, name)
      when 'promotion'
        get_promotion_template(relationship, tone, special_note, name)
      when 'graduation'
        get_graduation_template(relationship, tone, special_note, name)
      when 'award'
        get_award_template(relationship, tone, special_note, name)
      when 'appreciation'
        get_appreciation_template(relationship, tone, special_note, name)
      when 'anniversary'
        get_anniversary_template(relationship, tone, special_note, name)
      else
        get_general_template(relationship, tone, special_note, name)
      end
    end

    # 제목에서 목적 추론
    def get_purpose_from_title(title)
      return '' unless title.present?
      
      if title.include?('전역') || title.include?('퇴역') || title.include?('퇴직')
        'retirement'
      elsif title.include?('승진') || title.include?('임명') || title.include?('취업') || title.include?('입사')
        'promotion'
      elsif title.include?('졸업') || title.include?('수료') || title.include?('학위')
        'graduation'
      elsif title.include?('수상') || title.include?('표창') || title.include?('포상')
        'award'
      elsif title.include?('감사') || title.include?('고마')
        'appreciation'
      else
        ''
      end
    end

    # 퇴직/전역 템플릿
    def get_retirement_template(relationship, tone, special_note, name)
      relationship_context = get_relationship_context(relationship, 'retirement')
      tone_keywords = get_tone_keywords(tone, 'retirement')
      special_context = special_note.present? ? "특별히 #{special_note}에 대한 " : ""
      
      <<~TEMPLATE
        【퇴직/전역 맞춤 템플릿】
        관계적 맥락: #{relationship_context}
        특별 고려사항: #{special_context}감사와 축하
        
        구성 가이드:
        - 도입: "#{get_opening_phrase(relationship, tone, 'retirement')}"
        - 본문: "#{name}님의 #{special_note.present? ? special_note + '와 ' : ''}#{tone_keywords[:main]}에..."
        - 마무리: "#{get_closing_phrase(relationship, tone, 'retirement')}"
        
        핵심 키워드: #{tone_keywords[:keywords].join(', ')}
        감정 톤: #{get_emotional_tone('retirement', tone)}
      TEMPLATE
    end

    # 승진/임명 템플릿
    def get_promotion_template(relationship, tone, special_note, name)
      relationship_context = get_relationship_context(relationship, 'promotion')
      tone_keywords = get_tone_keywords(tone, 'promotion')
      special_context = special_note.present? ? "#{special_note}을/를 바탕으로 한 " : ""
      
      <<~TEMPLATE
        【승진/임명 맞춤 템플릿】
        관계적 맥락: #{relationship_context}
        특별 고려사항: #{special_context}새로운 시작 축하
        
        구성 가이드:
        - 도입: "#{get_opening_phrase(relationship, tone, 'promotion')}"
        - 본문: "#{name}님의 #{special_note.present? ? special_note + '과 ' : ''}#{tone_keywords[:main]}이..."
        - 마무리: "#{get_closing_phrase(relationship, tone, 'promotion')}"
        
        핵심 키워드: #{tone_keywords[:keywords].join(', ')}
        감정 톤: #{get_emotional_tone('promotion', tone)}
      TEMPLATE
    end

    # 기타 템플릿들 (간소화)
    def get_graduation_template(relationship, tone, special_note, name)
      get_general_template_with_purpose(relationship, tone, special_note, name, 'graduation', '학문적 성취', ['노력', '열정', '성취', '꿈', '미래'])
    end

    def get_award_template(relationship, tone, special_note, name)
      get_general_template_with_purpose(relationship, tone, special_note, name, 'award', '뛰어난 성과', ['업적', '공로', '성과', '인정', '자랑'])
    end

    def get_appreciation_template(relationship, tone, special_note, name)
      get_general_template_with_purpose(relationship, tone, special_note, name, 'appreciation', '소중한 기여', ['감사', '고마움', '헌신', '도움', '배려'])
    end

    def get_anniversary_template(relationship, tone, special_note, name)
      get_general_template_with_purpose(relationship, tone, special_note, name, 'anniversary', '의미있는 순간', ['기념', '추억', '소중함', '감동', '축하'])
    end

    def get_general_template(relationship, tone, special_note, name)
      get_general_template_with_purpose(relationship, tone, special_note, name, 'general', '노고와 헌신', ['진심', '감사', '인정', '격려', '응원'])
    end

    # 일반 템플릿 헬퍼
    def get_general_template_with_purpose(relationship, tone, special_note, name, purpose, main_theme, keywords)
      relationship_context = get_relationship_context(relationship, purpose)
      special_context = special_note.present? ? "#{special_note}에 대한 " : ""
      
      <<~TEMPLATE
        【#{get_purpose_description(purpose)} 맞춤 템플릿】
        관계적 맥락: #{relationship_context}
        특별 고려사항: #{special_context}#{main_theme} 강조
        
        구성 가이드:
        - 도입: "#{get_opening_phrase(relationship, tone, purpose)}"
        - 본문: "#{name}님의 #{special_note.present? ? special_note + '과 ' : ''}#{main_theme}에..."
        - 마무리: "#{get_closing_phrase(relationship, tone, purpose)}"
        
        핵심 키워드: #{keywords.join(', ')}
        감정 톤: #{get_emotional_tone(purpose, tone)}
      TEMPLATE
    end

    # 헬퍼 메서드들
    def get_relationship_context(relationship, purpose)
      case relationship
      when 'superior_to_subordinate' then "상급자가 부하직원에게 주는 공식적이고 격려적인 메시지"
      when 'colleague_to_colleague' then "동료가 동료에게 주는 동등하고 지지적인 메시지"  
      when 'subordinate_to_superior' then "부하직원이 상급자에게 주는 존경과 감사의 메시지"
      when 'family_to_family' then "가족이 가족에게 주는 따뜻하고 사랑스러운 메시지"
      when 'friend_to_friend' then "친구가 친구에게 주는 친근하고 응원하는 메시지"
      when 'organization_to_individual' then "기관이 개인에게 주는 공식적이고 권위있는 메시지"
      else "일반적이고 정중한 메시지"
      end
    end

    def get_tone_keywords(tone, purpose)
      base_keywords = {
        'retirement' => ['헌신', '봉사', '수고', '희생'],
        'promotion' => ['능력', '성과', '발전', '성장'],
        'graduation' => ['노력', '열정', '성취', '완수'],
        'appreciation' => ['감사', '고마움', '소중함', '배려']
      }
      
      case tone
      when 'warm'
        { main: '따뜻한 마음과 진정성', keywords: base_keywords[purpose] || ['진심', '마음', '정성'] }
      when 'concise'
        { main: '뛰어난 능력과 성과', keywords: base_keywords[purpose] || ['능력', '성과', '결과'] }
      else
        { main: '숭고한 헌신과 노고', keywords: base_keywords[purpose] || ['헌신', '노고', '정성'] }
      end
    end

    def get_opening_phrase(relationship, tone, purpose)
      case relationship
      when 'superior_to_subordinate' then tone == 'warm' ? "마음 깊이 감사드리며" : "공식적으로 표창하며"
      when 'subordinate_to_superior' then "깊은 존경과 감사의 마음으로"
      when 'colleague_to_colleague' then tone == 'warm' ? "동료로서 진심으로" : "같은 길을 걸어온 동료로서"
      else "진심어린 마음으로"
      end
    end

    def get_closing_phrase(relationship, tone, purpose)
      case tone
      when 'warm' then "언제나 행복하시길 진심으로 바랍니다"
      when 'concise' then "앞으로도 성공하시길 기원합니다"
      else "건강하시고 앞으로도 번영하시길 바랍니다"
      end
    end

    def get_emotional_tone(purpose, tone)
      emotions = {
        'retirement' => { 'warm' => '따뜻한 감사와 아쉬움', 'formal' => '깊은 존경과 감사', 'concise' => '간결한 인정과 축하' },
        'promotion' => { 'warm' => '진심어린 축하와 응원', 'formal' => '공식적인 축하와 격려', 'concise' => '명확한 축하와 기대' }
      }
      
      emotions.dig(purpose, tone) || '정중한 감사와 축하'
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

    def truncate_to_limit(text, limit)
      return text if text.length <= limit
      
      # 단어 경계에서 자르기 시도
      truncated = text[0, limit]
      last_space = truncated.rindex(' ')
      last_period = truncated.rindex('.')
      
      # 마지막 공백이나 마침표가 있으면 그 지점에서 자르기
      if last_period && last_period > limit * 0.8
        truncated = truncated[0, last_period + 1]
      elsif last_space && last_space > limit * 0.8
        truncated = truncated[0, last_space]
      end
      
      truncated.strip
    end
  end
end