# frozen_string_literal: true

RSpec.describe Transaction do
  it 'has a version number' do
    expect(Transaction::VERSION).not_to be nil
  end

  context 'Transaction' do
    let(:t) { Transaction::Client.new }

    after(:each) do
      t.clear!
    end

    it 'creates a new transaction with status queued' do
      expect(t.status).to eq('queued')
      expect(t.attributes).to eq(status: :queued)
      t.clear!
    end

    it 'fetches transaction by id' do
      t.update_status('success')

      t1 = Transaction::Client.new(transaction_id: t.transaction_id)
      expect(t1.status).to eq('success')

      t1.clear!
    end

    it '#start!' do
      t.start!

      expect(t.status).to eq('processing')
    end

    it '#refresh!' do
      t1 = Transaction::Client.new(transaction_id: t.transaction_id)
      t1.start!

      expect(t.status).to eq('queued')

      t.refresh!
      expect(t.status).to eq('processing')
    end

    context '#update_status' do
      it 'updates if valid status is passed' do
        t.update_status('success')

        expect(t.status).to eq('success')
      end

      it 'raises and error if invalid status is passed' do
        expect { t.update_status('wrong_status') }
          .to raise_error(RuntimeError, /Invalid Status/)
      end
    end

    context '#update_attributes' do
      it 'raises argument error if invalid type is passed' do
        expect { t.update_attributes('wrong_type') }
          .to raise_error(ArgumentError, /Invalid type. Expected Hash/)
      end

      it 'updates the attributes' do
        attrs = { failed: false }

        t.update_attributes(attrs)
        expect(t.attributes).to have_key(:failed)
        expect(t.attributes[:failed]).to eq(false)
      end
    end

    context '#finish!' do
      it 'finish with no clear' do
        t.finish!(status: 'success')

        expect(t.status).to eq('success')
      end

      it 'finish with clear = true to clear the transaction' do
        t.finish!(status: 'success', clear: true)

        expect(t.status).to eq('success')
        expect { t.refresh! }
          .to raise_error(StandardError, /Transaction expired/)
      end
    end
  end
end
