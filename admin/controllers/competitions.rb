CompetitionWatcher::Admin.controllers :competitions do
  get :index do
    @title = "Competitions"
    @competitions = Competition.all
    render 'competitions/index'
  end

  get :new do
    @title = pat(:new_title, :model => 'competition')
    @competition = Competition.new
    render 'competitions/new'
  end

  post :create do
    @competition = Competition.new(params[:competition])
    if @competition.save
      @title = pat(:create_title, :model => "competition #{@competition.id}")
      flash[:success] = pat(:create_success, :model => 'Competition')
      params[:save_and_continue] ? redirect(url(:competitions, :index)) : redirect(url(:competitions, :edit, :id => @competition.id))
    else
      @title = pat(:create_title, :model => 'competition')
      flash.now[:error] = pat(:create_error, :model => 'competition')
      render 'competitions/new'
    end
  end

  get :edit, :with => :id do
    @title = pat(:edit_title, :model => "competition #{params[:id]}")
    @competition = Competition.find(params[:id])
    if @competition
      render 'competitions/edit'
    else
      flash[:warning] = pat(:create_error, :model => 'competition', :id => "#{params[:id]}")
      halt 404
    end
  end

  put :update, :with => :id do
    @title = pat(:update_title, :model => "competition #{params[:id]}")
    @competition = Competition.find(params[:id])
    if @competition
      if @competition.update_attributes(params[:competition])
        flash[:success] = pat(:update_success, :model => 'Competition', :id =>  "#{params[:id]}")
        params[:save_and_continue] ?
          redirect(url(:competitions, :index)) :
          redirect(url(:competitions, :edit, :id => @competition.id))
      else
        flash.now[:error] = pat(:update_error, :model => 'competition')
        render 'competitions/edit'
      end
    else
      flash[:warning] = pat(:update_warning, :model => 'competition', :id => "#{params[:id]}")
      halt 404
    end
  end

  delete :destroy, :with => :id do
    @title = "Competitions"
    competition = Competition.find(params[:id])
    if competition
      if competition.destroy
        flash[:success] = pat(:delete_success, :model => 'Competition', :id => "#{params[:id]}")
      else
        flash[:error] = pat(:delete_error, :model => 'competition')
      end
      redirect url(:competitions, :index)
    else
      flash[:warning] = pat(:delete_warning, :model => 'competition', :id => "#{params[:id]}")
      halt 404
    end
  end

  delete :destroy_many do
    @title = "Competitions"
    unless params[:competition_ids]
      flash[:error] = pat(:destroy_many_error, :model => 'competition')
      redirect(url(:competitions, :index))
    end
    ids = params[:competition_ids].split(',').map(&:strip)
    competitions = Competition.find(ids)
    
    if Competition.destroy competitions
    
      flash[:success] = pat(:destroy_many_success, :model => 'Competitions', :ids => "#{ids.to_sentence}")
    end
    redirect url(:competitions, :index)
  end
end
