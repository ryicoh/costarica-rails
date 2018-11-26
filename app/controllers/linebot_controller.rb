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
      if Line::Bot::Event::Message === event && Line::Bot::Event::MessageType::Text === event.type
        say_message = event.message['text']
        user_id = event['source']['userId']
        profile = JSON.parse(client.get_profile(user_id).body)

        chef = Chef.new({user_id: user_id, user_name: profile['displayName'], count: 0 })
        text = ''
        if chef.save
          text = 'ok'
        else
          text = 'no'
        end

        message = {
          type: 'text',
          text: "reply: #{text}"
        }
        response = client.reply_message(event['replyToken'], message)
      end

      render status: 200, json: { message: 'OK' }
    end
  end
end
