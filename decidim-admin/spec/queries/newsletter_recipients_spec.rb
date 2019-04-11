# frozen_string_literal: true

require "spec_helper"

module Decidim::Admin
  describe NewsletterRecipients do
    subject { described_class.new(newsletter, form) }

    let(:newsletter) { create :newsletter }
    let(:send_to_all_users) { true }
    let(:send_to_followers) { false }
    let(:send_to_participants) { false }
    let(:participatory_space_types) { [] }
    let(:scope_ids) { [] }

    let(:form_params) do
      {
        send_to_all_users: send_to_all_users,
        send_to_followers: send_to_followers,
        send_to_participants: send_to_participants,
        participatory_space_types: participatory_space_types,
        scope_ids: scope_ids
      }
    end

    let(:form) do
      SelectiveNewsletterForm.from_params(
        form_params
      ).with_context(
        current_organization: newsletter.organization
      )
    end

    describe "querying recipients" do
      context "when sending to all users" do
        let!(:recipients) { create_list(:user, 5, :confirmed, newsletter_notifications_at: Time.current, organization: newsletter.organization) }

        it "returns all users" do
          expect(subject.query).to match_array recipients
          expect(recipients.count).to eq 5
        end
      end

      context "when sending to followers" do
        let!(:recipients) { create_list(:user, 3, :confirmed, newsletter_notifications_at: Time.current, organization: newsletter.organization) }
        let(:send_to_all_users) { false }
        let(:send_to_followers) { true }
        let(:participatory_processes) { create_list(:participatory_process, 2, organization: newsletter.organization) }
        let(:participatory_space_types) do
          [
            { "id" => nil,
              "manifest_name" => "participatory_processes",
              "ids" => [participatory_processes.first.id.to_s] },
            { "id" => nil,
              "manifest_name" => "assemblies",
              "ids" => [] },
            { "id" => nil,
              "manifest_name" => "conferences",
              "ids" => [] },
            { "id" => nil,
              "manifest_name" => "consultations",
              "ids" => [] },
            { "id" => nil,
              "manifest_name" => "initiatives",
              "ids" => [] }
          ]
        end

        context "when recipients follow the participatory space" do
          before do
            recipients.each do |follower|
              create(:follow, followable: participatory_processes.first, user: follower)
            end
          end

          it "returns all users" do
            expect(subject.query).to match_array recipients
            expect(recipients.count).to eq 3
          end
        end

        context "when recipients not follow the participatory space" do
          it "don't retrun recipients" do
            expect(subject.query).to match_array []
          end
        end
      end
    end
  end
end
