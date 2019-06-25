class PagesController < ApplicationController
  include SessionsHelper

  def home
    if logged_in?
      @user = current_user
      if @user.nil?
        session[:user_id] = nil
      else
        cnt = Post.where(posted_by: @user.twitterid).count
        if cnt % 8 == 0
          @count = cnt / 8
        else
          @count = cnt / 8 + 1
        end
        @posts = Post.where(posted_by: @user.twitterid).reverse_order.limit(8)
      end
      @index = 1

      get_record_stat
    end
  end

  def move
    @user = current_user
    @index = params[:index]
    @btn = (params[:index].to_i + 1).to_s
    cnt = Post.where(posted_by: @user.twitterid).count
    if cnt % 8 == 0
      @count = cnt / 8
    else
      @count = cnt / 8 + 1
    end
    @start = params[:index].to_i * 8
    @posts = Post.where(posted_by: @user.twitterid).reverse_order.offset(@start).limit(8)
  end

  def edit
    @post = Post.find(params[:post])
  end

  private
  LEGEND_LIMIT = 4
  def get_record_stat
    # 対象レコードデータ
    # TODO: 検索対象の指定
    record = Post.where(posted_by: current_user.twitterid).reverse_order.limit(100)

    # 最近のアーティスト比率
    ## ユーザの最新100件のうち，アーティストと出現回数の組を取得
    data = record.group(:artist).count.sort_by{|a| a[1]}.reverse
    ## ハッシュに出現数を記録
    artists_count = {
      labels: [],
      datasets: [{
        data: [],
        backgroundColor: [
          "#594157",
          "#726DA8",
          "#7D8CC4",
          "#A0D2DB",
          "#BEE7E8"
        ]
      }]
    }
    data.each_with_index do |d, index|
      if index == LEGEND_LIMIT
        break
      end
      artists_count[:labels] << d[0]
      artists_count[:datasets][0][:data] << d[1]
    end
    ## その他処理
    if data.length > LEGEND_LIMIT
      others_sum = 0
      for d in data[LEGEND_LIMIT..data.length] do
        others_sum += d[1]
      end
      artists_count[:labels] << "その他"
      artists_count[:datasets][0][:data] << others_sum
    end
    gon.artists_count = artists_count

    # 曲のランキング
    data = record.group(:artist, :song).count.sort_by{|a| a[1]}.reverse[0..2]
    gon.song_rank = data
    @rank = data

  end
end
