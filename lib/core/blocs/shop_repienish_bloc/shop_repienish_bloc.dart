import 'dart:async';

import 'package:absolute_app/core/apis/api_calls.dart';
import 'package:absolute_app/models/shop_replinsh_model.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'shop_repienish_event.dart';
part 'shop_repienish_state.dart';

class ShopRepienishBloc extends Bloc<ShopRepienishEvent, ShopRepienishState> {
  ShopRepienishBloc() : super(ShopRepienishInitialState()) {
    on<ShopRepienishEvent>((event, emit) async{
      emit(ShopRepienishInitialState());

      try{
        List<ShopReplenishSku> data = await ApiCalls.returnShopReplenishList();
        emit(ShopRepienishLoadedState(list: data));
      } catch(e){
        emit(ShopRepienishErrorState(errorMessage: e.toString()));
      }
    });
  }
}
