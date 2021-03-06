# Controller for the Scorekeeper leaf. This class contains only the methods
# directly relating to IRC. Other methods are stored in the helper and model
# classes.

class Controller < Autumn::Leaf
  
  # Displays an about message.
  
  def about_command(stem, sender, reply_to, msg)
  end
  
  # Displays the current point totals, or modifies someone's score, depending on
  # the message provided with the command.
  
  def points_command(stem, sender, reply_to, msg)
    if msg.nil? or msg.empty? then
      var :totals => totals(stem, reply_to)
    elsif msg =~ /^(#{stem.nick_regex})\s+history\s*(.*)$/ then
      parse_history stem, reply_to, $1, $2
      render :history
    elsif msg =~ /^(#{nick_regex})\s+([\+\-]\d+)\s*(.*)$/ then
      parse_change stem, reply_to, sender, $1, $2.to_i, $3
      render :change
    else
      render :usage
    end
  end
  
  private
  
  def points(stem, channel)
    chan = Channel.find_or_create(:server => server_identifier(stem), :name => channel)
    scores = chan.scores.all
    scores.inject(Hash.new(0)) { |hsh, score| hsh[score.receiver.name] += score.change; hsh }
  end

  def totals(stem, channel)
    points(stem, channel).sort { |a,b| b.last <=> a.last }
  end

  def parse_change(stem, channel, sender, victim, delta, note)
    giver = find_person(stem, sender[:nick])
    receiver = find_person(stem, victim)
    if giver.nil? and options[:scoring] == 'open' then
      giver ||= Person.create(:server => server_identifier(stem), :name => sender[:nick])
    end
    if receiver.nil? and options[:scoring] == 'open' then
      receiver ||= Person.create(:server => server_identifier(stem), :name => find_in_channel(stem, channel, victim))
    end
    unless authorized?(giver, receiver)
      var :unauthorized => true
      var :receiver => receiver.nil? ? victim : receiver.name
      return
    end
    change_points stem, channel, giver, receiver, delta, note
    var :giver => giver
    var :receiver => receiver
    var :delta => delta
  end
  
  def parse_history(stem, channel, subject, argument)
    date = argument.empty? ? nil : parse_date(argument)
    scores = Array.new
    
    chan = Channel.named(channel).first
    person = find_person(stem, subject)
    if person.nil? then
      var :person => subject
      var :no_history => true
      return
    end
    
    if date then
      start, stop = find_range(date)
      scores = chan.scores.given_to(person).between(start, stop).newest_first.all(:limit => 5)
    elsif argument.empty? then
      scores = chan.scores.given_to(person).newest_first.all(:limit => 5)
    else
      giver = find_person(stem, argument)
      if giver.nil? then
        var :giver => argument
        var :receiver => person
        var :no_giver_history => true
        return
      end
      scores = chan.scores.given_by(giver).given_to(person).newest_first.all(:limit => 5)
    end
    var :receiver => person
    var :giver => giver
    var :scores => scores
  end
end
