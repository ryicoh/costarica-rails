require 'line/bot'

class LinebotController < ApplicationController
  protect_from_forgery except: :callback

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end

  def callback
    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      error 400 do 'Bad Request' end
    end

    events = client.parse_events_from(body)
    events.each do |event|
      if Line::Bot::Event::Message === event && \
         Line::Bot::Event::MessageType::Text === event.type && \
         event['source']['type'] == 'group'

        @replyToken = event['replyToken']
        say_message, @argument = split_text(event.message['text'])

        @user_id = event['source']['userId']
        @group_id = event['source']['groupId']
        @user_name = JSON.parse(client.get_profile(@user_id).body)['displayName']

        unless @group_id
          send_message("グループで使ってね")
          return
        end

        help if ['ヘルプ'].include?(say_message)
        show_count if ['回数'].include?(say_message)
        cook if ['任せろ'].include?(say_message)
        set_alias if ['エイリアス'].include?(say_message)
        set_count if ['セット'].include?(say_message)
      end

      render status: 200, json: { message: 'OK' }
    end
  end

  private

  def help
    text = <<~USAGE
      '回数'　: 担当回数が見れるよ
      '任せろ': 料理は任せたぜ！
      'シェフだれ？': 今日のシェフ決め
      'セット [数字]': 回数を設定
      'エイリアス [名前]': 名前変更
      'bye'  : グループから去ります
    USAGE
    send_message(text.rstrip)
  end

  def show_count
    text = Chef.find_by_group_id(@group_id).reduce('') do |str, chef|
      str += "#{chef['alias_name'] ? chef['alias_name'] :
              chef['user_name']}: #{chef['count']}回\n"
    end

    text = 'シェフがいないようだ' if text == ''

    send_message(text.rstrip)
  end

  def cook
    chef = Chef.find_by_user_id_and_group_id(@user_id, @group_id)

    unless chef
      chef = Chef.new({ user_id: @user_id, group_id: @group_id, user_name: @user_name, count: 0 })
      send_message('新しいシェフだね！')
    else
      chef.count += 1
    end

    chef.save

    text = "今日のシェフは#{chef.alias_name ? chef.alias_name : chef.user_name}だ"
    text += '¥n今日のご飯は上手くなるぞ！' if rand(10) == 0
    send_message(text)
  end

  def set_alias
    chef = Chef.find_by_user_id_and_group_id(@user_id,
                                             @group_id)
    unless chef
      send_message('シェフではないな？？')
      return
    end

    chef.alias_name = @argument
    chef.save

    send_message("#{@argument}とお呼びしますね！")
  end

  def set_count
    unless @argument =~ /^[0-9]+$/
      send_message('ミス\nセット [数字]\nと入力してね')
      return
    end
    count = @argument.to_i
      
    chef = Chef.find_by_user_id_and_group_id(@user_id, @group_id)
    unless chef
      chef = Chef.new({ user_id: @user_id, group_id: @group_id, user_name: @user_name, count: count })
      send_message('新しいシェフだね！')
    else
      chef.count = count
      send_message('セットした〜♫')
    end
    chef.save
  end
  
  def send_message text
    client.reply_message(@replyToken, {
      type: 'text',
      text: text
    })
  end

  def split_text text
    [' ', '　'].each do |sep|
      texts = text.split(sep)
      if texts.size == 2
        return texts
      end
    end

    [text, '']
  end
end
