RSpec.describe Transaction do
  it 'has a version number' do
    expect(Transaction::VERSION).not_to be nil
  end

  it 'does something useful' do
    expect(false).to eq(true)
  end
end
