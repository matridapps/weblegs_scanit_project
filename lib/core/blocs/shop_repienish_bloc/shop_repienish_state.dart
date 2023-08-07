part of 'shop_repienish_bloc.dart';

abstract class ShopRepienishState extends Equatable {
  const ShopRepienishState();
}

class ShopRepienishInitialState extends ShopRepienishState {
  @override
  List<Object> get props => [];
}
class ShopRepienishLoadingState extends ShopRepienishState {
  @override
  List<Object> get props => [];
}
class ShopRepienishLoadedState extends ShopRepienishState {

  final List<ShopReplenishSku> list;

  const ShopRepienishLoadedState({required this.list});

  @override
  List<Object> get props => [list];
}
class ShopRepienishErrorState extends ShopRepienishState {

  final String errorMessage;


  const ShopRepienishErrorState({required this.errorMessage});

  @override
  List<Object> get props => [errorMessage];
}
