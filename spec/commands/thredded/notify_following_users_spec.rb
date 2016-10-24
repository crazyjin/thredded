# frozen_string_literal: true
require 'spec_helper'
# rubocop:disable StringLiterals

module Thredded
  describe NotifyFollowingUsers do
    describe '#targetted_users' do
      let(:post) { create(:post, user: poster, postable: topic) }
      let(:poster) { create(:user, name: "poster") }
      let!(:follower) { create(:user_topic_follow, user: create(:user, name: "follower"), topic: topic).user }
      let(:topic) { create(:topic, messageboard: messageboard) }
      let!(:messageboard) { create(:messageboard) }
      subject { NotifyFollowingUsers.new(post).targeted_users }

      it "includes followers where preference to receive these notifications" do
        create(
          :user_messageboard_preference,
          followed_topic_emails: true,
          user: follower,
          messageboard: messageboard
        )
        expect(subject).to include(follower)
      end

      it "doesn't include the poster, even if they follow" do
        create(:user_topic_follow, user: poster, topic: topic)
        expect(subject).to_not include(poster)
      end

      it "doesn't include followers where notification turned off" do
        create(
          :user_messageboard_preference,
          followed_topic_emails: false,
          user: follower,
          messageboard: messageboard
        )
        expect(subject).not_to include(follower)
      end
    end

    describe '#run' do
      let(:post) { create(:post) }

      let(:command) { NotifyFollowingUsers.new(post) }
      let(:targeted_users) { [build_stubbed(:user)] }
      before { allow(command).to receive(:targeted_users).and_return(targeted_users) }

      it "sends an email to targetted users" do
        expect { command.run }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end
      it "records notifications" do
        expect { command.run }.to change { PostNotification.count }.by(1)
      end
    end
  end
end
