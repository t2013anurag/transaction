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

  context 'Transaction with pubsub client' do
    # Used pusher for testing purposes.
    def stub_pusher(channel_name, data)
      client = Transaction.pubsub_client

      expect(PusherClient).to receive(:trigger).with(
        # transaction_id is assigned as channel name if it is not present
        channel_name || t.transaction_id,
        Transaction.pubsub_client[:event],
        data
      ).and_return(true)
    end

    let(:t) { Transaction::Client.new }

    before(:all) do
      PusherClient = Pusher::Client.new(
        app_id: 'some_app_id',
        key: 'pusher_key',
        secret: 'pusher_secret',
        cluster: 'cluster',
        use_tls: true
      )

      Transaction.pubsub_client = {
        client: PusherClient,
        trigger: 'trigger'
      }
    end

    after(:each) do
      t.clear!
    end

    it 'triggers an event on start!' do
      stub_pusher(nil, message: 'Processing', status: 'processing')
      t.start!
    end

    it 'triggers an event on finish!' do
      stub_pusher(nil, message: 'Done', status: 'success')
      t.finish!(status: 'success', clear: true)
    end

    it '#trigger_event!' do
      stub_pusher(nil, count: 1, status: 'queued')
      t.trigger_event!(count: 1)
    end

    it 'user defined channel and event' do
      channel_name = 'my_transaction_channel'

      Transaction.pubsub_client = {
        client: PusherClient,
        trigger: 'trigger',
        channel_name: channel_name,
        event: 'new_event'
      }

      data = { message: 'Processing', status: 'processing' }
      stub_pusher(channel_name, data)
      t.start!
    end
  end
end
