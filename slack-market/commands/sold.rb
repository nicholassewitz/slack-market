module SlackMarket
  module Commands
    class Sold < SlackRubyBot::Commands::Base
      command 'sold' do |client, data, match|
        user = ::User.find_create_or_update_by_slack_id!(client, data.user)
        expression = match['expression'] if match['expression']
        stocks = Market.qualify(expression.split, client.owner.dollars?) if expression
        quotes = Market.quotes(stocks) if stocks
        quotes.each do |quote|
          logger.info "#{client.owner}, user=#{user} - SOLD #{quote.name} (#{quote.symbol}): $#{quote.last_trade_price}"
          positions = user.positions.where(symbol: quote.symbol, sold_at: nil)
          if positions.any?
            positions.update_all(sold_at: Time.now.utc, sold_price_cents: quote.last_trade_price.to_f * 100)
            client.say channel: data.channel, text: "#{user.slack_mention} sold #{quote.name} (#{quote.symbol}) at ~$#{quote.last_trade_price}"
          else
            client.say channel: data.channel, text: "#{user.slack_mention} does not hold #{quote.name} (#{quote.symbol})"
          end
        end if quotes.any?
      end
    end
  end
end
