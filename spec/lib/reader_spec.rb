RSpec.describe Grell::Reader do

  context 'Waiting time expired' do
    let(:waiting_time) {0}
    let(:sleeping_time) {2}
    let(:condition) {false}
    it 'does not sleep' do
      before_time = Time.now
      Grell::Reader.wait_for(->{''}, waiting_time, sleeping_time) do
        condition
      end
      expect(Time.now - before_time < 1)
    end
  end

  context 'The condition is true' do
    let(:waiting_time) {3}
    let(:sleeping_time) {2}
    let(:condition) {true}
    it 'does not sleep' do
      before_time = Time.now
      Grell::Reader.wait_for(->{''}, waiting_time, sleeping_time) do
        condition
      end
      expect(Time.now - before_time < 1)
    end
  end

  context 'The condition is false' do
    let(:waiting_time) {2}
    let(:sleeping_time) {3}
    let(:condition) {false}
    before do
      allow(Time).to receive(:now).and_return(1, 1, 4)
    end

    it 'waits the waiting time' do
      expect(Grell::Reader).to receive(:sleep).once
      Grell::Reader.wait_for(->{''}, waiting_time, sleeping_time) do
        condition
      end
    end

  end

end