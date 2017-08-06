RSpec.describe String do
  describe '#intersection' do
    it 'finds common substrings' do
      expect('canada'.intersection('canary')).to eq('cana')
    end

    it 'selects the longest common substring if there is more than one' do
      expect('curate'.intersection('ur-rat')).to eq('rat')
    end
  end

  describe '#unescape' do
    it 'removes double quotes (for mbsync config strings)' do
      expect('!"foobar"'.unescape).to eq('!foobar')
    end

    it 'removes backslashes' do
      expect('foobar\?'.unescape).to eq('foobar?')
    end
  end
end
