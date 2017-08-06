# RSpec.describe LittleRedFlag::MailAgent::Mbsync do
#   let(:dotfile) { "#{__dir__}/data/mbsyncrc" }

#   describe 'dotfile parsing' do
#     describe '::new' do
#       it 'accepts the path of an rc file' do
#         expect(described_class.new(dotfile)).to be_truthy
#       end
#     end
#   end
# end

RSpec.describe LittleRedFlag::MailAgent::Mbsync::Config::RCFile do
  let(:dotfile) { "#{__dir__}/data/mbsyncrc" }
  subject       { described_class.new(dotfile) }

  describe '#sanitize!' do
    it 'removes comments' do
      expect(subject.sanitize.scan(/^#.*$/).count).to be 0
    end

    it 'removes extraneous whitespace' do
      expect(subject.sanitize.scan(/\n\n\n/).count).to be 0
    end

    it 'preserves regular lines' do
      expect { subject.sanitize }
        .not_to change { subject.scan(/^\w+ .+$/).count }
    end

    it 'adheres to a strict whitespace format' do
      stanza_head = ".+"
      stanza_body = '(\n.+)+'
      stanza      = "(#{stanza_head}#{stanza_body})"
      stanzas     = "#{stanza}(\n\n#{stanza})+"

      expect(subject.sanitize).to match(/\A#{stanzas}\Z/)
    end
  end
end

RSpec.describe LittleRedFlag::MailAgent::Mbsync::Config::Section do
  let(:channel) do
    <<-HERE.gsub(/^\s{6}/, '')
      Channel hello
      Master :hello:INBOX
      Slave :local:<<Hello>>
      Create Slave
      Expunge Both
      SyncState *
    HERE
  end

  let(:group) do
    <<-HERE.gsub(/^\s{6}/, '')
      Group inboxes
      Channel hello
      Channel lists
      Channel gmail-inbox
      Channel gmail-drafts
      Channel gmail-sent
    HERE
  end

  subject { described_class.new(channel) }

  describe '::new' do
    it 'populates #type with Section Keyword' do
      expect(subject.type).to eq('channel')
    end

    it 'populates #label with Section Argument' do
      expect(subject.label).to eq('hello')
    end
  end

  describe '#to_h' do
    it 'converts raw string section into hash' do
      expect(subject.split("\n", 2).last.to_h)
        .to eq({ master:    ':hello:INBOX',
                 slave:     ':local:<<Hello>>',
                 create:    'slave',
                 expunge:   'both',
                 syncstate: '*' })
    end

    it 'assembles duplicate setting keywords into arrays' do
      expect(described_class.new(group).split("\n", 2).last.to_h[:channels])
        .to eq(['hello', 'lists', 'gmail-inbox', 'gmail-drafts', 'gmail-sent'])
    end
  end
end
