class ContactUsController < ApplicationController

  def new
    @url = params[:url]
  end

  def submit
    if params[:report][:type] == "problem"
      ContactUsMailer.error_report(params[:user_id], params[:report][:url], params[:report][:description]).deliver

      respond_to do |format|
        format.html { redirect_to params[:report][:url], notice: 'Error report successfully submitted! Thank you!' }
      end
    
    elsif params[:report][:type] == "feedback"
      ContactUsMailer.feedback(params[:user_id], params[:report][:description]).deliver

      respond_to do |format|
        format.html { redirect_to params[:report][:url], notice: 'Sucessfully submitted! Thank you for your feedback!' }
      end
    elsif params[:report][:type] == "other"
      ContactUsMailer.other(params[:user_id], params[:report][:description]).deliver

      respond_to do |format|
        format.html { redirect_to params[:report][:url], notice: 'Thank you for your feedback. We\'ll get back to you soon!'}
      end
    end

  end

end