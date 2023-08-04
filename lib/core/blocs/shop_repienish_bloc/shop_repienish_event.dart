part of 'shop_repienish_bloc.dart';

abstract class ShopRepienishEvent extends Equatable {
  const ShopRepienishEvent();
}

class ShopRepienishLoadingEvent extends ShopRepienishEvent {
  @override
  List<Object?> get props => [];
}
