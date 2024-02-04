#require 'spec_helper'

require_relative '../../lib/beats/album'
require_relative '../../lib/beats/track'
require_relative '../../lib/beats/vinyl_track'

describe Beats::VinylTrack do
  describe '#amplification_amount' do
    let(:track) { Beats::Track.new number: 1, label: '1', description: 'foo' }
    let(:album) { Beats::Album.new serial: '123', artist: 'foo', title: 'bar', year: '1234', tracks: [track] }
    let(:vinyl) { described_class.new album: album, track: track }

    subject { vinyl.amplification_amount current }

    context 'currently -10dB' do
      let(:current) { -10.0 }
      it { is_expected.to eq 4.96 }
    end

    context 'currently MAX_VOLUME' do
      let(:current) { MAX_VOLUME }
      it { is_expected.to eq 0 }
    end

    context 'currently -1' do
      let(:current) { -1.0 }
      it { is_expected.to eq -4.04 }
    end

    context 'currently 0' do
      let(:current) { 0.0 }
      it { is_expected.to eq MAX_VOLUME }
    end

    context 'currently -1' do
      let(:current) { 5.0 }
      it { is_expected.to eq -10.04 }
    end
  end
end

