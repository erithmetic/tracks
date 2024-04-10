#require 'spec_helper'

require_relative '../../lib/beats/ffmpeg'

describe Beats::FFMPEG do
  describe '.info' do
    before { allow(Beats::FFMPEG).to receive(:execute).and_return(File.read(File.expand_path('../../metadata.txt', __FILE__))) }
    subject { Beats::FFMPEG.info '/path/to/file.flac' }

    it 'parses all the fields' do
      expect(subject).to eq({
        ALBUM: 'BARKER001',
        album_artist: 'Barker',
        ARTIST: 'Barker',
        comment: '1A - Energy 6 - Visit https://sambarker.bandcamp.com',
        DATE: '2019',
        TITLE: 'Neuron Colider',
        track: '1',
      })
    end
  end
end