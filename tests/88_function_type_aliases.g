// Feature Test 88: Calling function and closure type aliases across locals, params, fields, arrays, and generics

type IntUnary = (int) -> int;
type NestedUnary = IntUnary;
type Mapper<T, R> = (T) -> R;
type VoidTagHandler = (int) -> void;
type CCallback = void (*fn)(int);

int gLastTag = 0;

void recordTag(int tag) {
  gLastTag = gLastTag + tag;
}

struct HandlerBox {
  IntUnary transform;
  VoidTagHandler onTag;
}

type BoxAlias = HandlerBox;
type BoxPtrAlias = HandlerBox*;

int invokeParam(IntUnary fn, int x) {
  return fn(x);
}

int invokeNested(NestedUnary fn, int x) {
  return fn(x);
}

int gOffset = 5;

IntUnary makeOffsetAdder() {
  return {int x -> x + gOffset;};
}

int applyMapper(Mapper<int, int> fn, int value) {
  return fn(value);
}

int addOne(int x) {
  return x + 1;
}

int applyWithTransform(Mapper<IntUnary, int> runner, IntUnary fn) {
  return runner(fn);
}

int main() {
  IntUnary inc = {int x -> x + 1;};
  if (inc(41) != 42) {
    return 1;
  }

  NestedUnary dbl = {int x -> x * 2;};
  if (dbl(21) != 42) {
    return 2;
  }

  if (invokeParam(inc, 9) != 10 || invokeNested(dbl, 7) != 14) {
    return 3;
  }

  if (invokeParam(addOne, 41) != 42) {
    return 9;
  }

  if (makeOffsetAdder()(37) != 42) {
    return 4;
  }

  HandlerBox box = HandlerBox{
    transform: inc,
    onTag: {int tag -> gLastTag = gLastTag + tag; return;}
  };
  if (box.transform(99) != 100) {
    return 5;
  }
  box.onTag(15);

  BoxAlias aliasBox = box;
  if (aliasBox.transform(10) != 11) {
    return 6;
  }

  BoxPtrAlias ptrBox = &box;
  ptrBox.onTag(27);

  CCallback ccb = recordTag;
  ccb(100);
  if (gLastTag != 142) {
    return 7;
  }

  Mapper<int, int> sq = {int x -> x * x;};
  if (sq(6) != 36 || applyMapper(sq, 7) != 49) {
    return 8;
  }

  if (applyWithTransform({IntUnary fn -> fn(20) * 2;}, addOne) != 42) {
    return 10;
  }

  IntUnary[2] fns = [inc, dbl];
  if (fns[0](5) + fns[1](5) != 16) {
    return 11;
  }

  return 0;
}
