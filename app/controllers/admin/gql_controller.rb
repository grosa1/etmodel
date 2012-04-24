class Admin::GqlController < Admin::BaseController
  def search
    @q = params[:q]
    @output_element_series = OutputElementSerie.gquery_contains(@q)
    @constraints           = Constraint.gquery_contains(@q)
    @targets          = Target.gquery_contains(@q)
    @sidebar_items = SidebarItem.gquery_contains(@q)
  end

end
