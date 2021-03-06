require 'prawn'

include RbCommonHelper

class RbStoriesController < RbApplicationController
  unloadable
  include BacklogsCards
  
  def index
    if ! LabelStock.selected_label
      render :text => "No label stock selected. How did you get here?", :status => 500
      return
    end

    begin
      cards = Cards.new(params[:sprint_id] ? @sprint.stories : RbStory.product_backlog(@project), params[:sprint_id], current_language)
    rescue Prawn::Errors::CannotFit
      render :text => "There was a problem rendering the cards. A possible error could be that the selected font exceeds a render box", :status => 500
      return
    end

    respond_to do |format|
      format.pdf {
        send_data(cards.pdf.render, :disposition => 'attachment', :type => 'application/pdf')
      }
    end
  end
  
  def create
    params['author_id'] = User.current.id
    begin
      story = RbStory.create_and_position(params)
    rescue => e
      render :text => e.message.blank? ? e.to_s : e.message, :status => 400
      return
    end

    status = (story.id ? 200 : 400)
    
    respond_to do |format|
      format.html { render :partial => "story", :object => story, :status => status }
    end
  end

  def update
    story = RbStory.find(params[:id])
    begin
      result = story.update_and_position!(params)
    rescue => e
      render :text => e.message.blank? ? e.to_s : e.message, :status => 400
      return
    end

    story.reload
    status = (result ? 200 : 400)
    
    respond_to do |format|
      format.html { render :partial => "story", :object => story, :status => status }
    end
  end

end
