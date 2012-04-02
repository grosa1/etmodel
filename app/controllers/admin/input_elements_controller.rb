module Admin
  class InputElementsController < BaseController
    before_filter :find_model, :only => [:show, :edit]

    def index
      if params[:slide_id]
        @slide = Slide.find params[:slide_id]
        @input_elements = @slide.sliders
      else
        @input_elements = InputElement.all
      end
    end


    def new
      @input_element = InputElement.new
      @input_element.build_area_dependency
      @input_element.build_description
    end

    def create
      @input_element = InputElement.new(params[:input_element])

      if @input_element.save
        flash[:notice] = "InputElement saved"
        redirect_to admin_input_elements_url
      else
        render :action => 'new'
      end
    end

    def update
      @input_element = InputElement.find(params[:id])

      if @input_element.update_attributes(params[:input_element])
        ["nl","en"].each do |l|
          expire_fragment("slider_#{@input_element.id}_#{l}")
        end
        flash[:notice] = "InputElement updated"
        redirect_to admin_input_elements_url
      else
        render :action => 'edit'
      end
    end

    def destroy
      @input_element = InputElement.find(params[:id])
      if @input_element.destroy
        dependent = Interface.with_input_element(@input_element.key).map(&:key) rescue nil
        flash[:notice] = "Input element deleted. "
        flash[:notice] += "Please update these interfaces: #{dependent.join(' ,')}" if dependent
        redirect_to admin_input_elements_url
      else
        flash[:error] = "Error while deleting slider."
        redirect_to admin_input_elements_url
      end
    end

    def show
    end

    def edit
      @input_element.build_description unless @input_element.description
      @input_element.build_area_dependency unless @input_element.area_dependency
    end

    private

      def find_model
        if params[:version_id]
          @version = Version.find(params[:version_id])
          @input_element = @version.reify
          flash[:notice] = "Revision"
        else
          @input_element = InputElement.find(params[:id])
        end
      end
  end
end
