package view;

import doom.html.Component;
import doom.html.Html.*;
import State;
import dr.DiceParser.DiceParseError;
using thx.Arrays;
using thx.Functions;
using thx.Nel;
using thx.Strings;
import dr.DiceExpression;
import dr.DiceExpressionExtensions;
import Loc.msg;

class ExpressionInput extends Component<SimulatorProps> {
  override function render() {
    var value = switch props.expr {
      case Unparsed(src): src;
      case Parsed(src, _): src;
      case ParsedInvalid(src, _, _): src;
      case Error(src, _): src;
    }
    var top = [div([
        "class" => "expression-input"
      ],
      Tooltip.render(
        props.displayTooltip,
        new Editable({ value: value, change: onChange, focus: true }).asNode(),
        msg.typeHere
      )
    )];
    var bottom = switch props.expr {
          case Error(_, err):
            [div(["class" => "error"], renderParseError(err))];
          case ParsedInvalid(_, err, _):
            [div(["class" => "error"], renderValidationsErrors(err))];
          case _:
            [];
        };
    return div(top.concat(bottom));
  }

  static function renderValidationsErrors(err: Nel<ValidationMessage>) {
    return div([
      div(["class" => "validation-prefix"], msg.validationPrefix.sampleOne()),
      div(["class" => "validation-messages"],
        err.toArray().map(function(e) {
          return div(["class" => "validation-message"], validationMessage(e));
        })
      )
    ]);
  }

  static function rangeToString(range: Range) {
    return switch range {
      case Exact(value):
        msg.exact.replace("$value", '$value');
      case Between(minInclusive, maxInclusive):
        msg.between
          .replace("$minInclusive", '$minInclusive')
          .replace("$maxInclusive", '$maxInclusive');
      case ValueOrMore(value):
        msg.valueOrMore.replace("$value", '$value');
      case ValueOrLess(value):
        msg.valueOrLess.replace("$value", '$value');
      case Composite(arr): arr.map(rangeToString).join(' ${msg.or} ');
    };
  }

  static function validationMessage(m: ValidationMessage) {
    return switch m {
      case InsufficientSides(sides):
        msg.insufficientSides.replace("$sides", '$sides');
      case EmptySet:
        msg.emptySet;
      case InfiniteReroll(sides, range):
        msg.infiniteReroll
          .replace("$sides", '$sides')
          .replace("$range", rangeToString(range));
      case TooManyDrops(available, toDrop):
        msg.tooManyDrops
          .replace("$available", '$available')
          .replace("$toDrop", '$toDrop');
      case TooManyKeeps(available, toKeep):
        msg.tooManyKeeps
          .replace("$available", '$available')
          .replace("$toKeep", '$toKeep');
      case DropOrKeepShouldBePositive:
        msg.dropOrKeepShouldBePositive;
    };
  }

  static function renderParseError(err: DiceParseError) {
    return [span(["class" => "label"], msg.expectedOneOf), br()]
    .concat(
      err.expected
        .map.fn(span(["class" => "expected"], _))
        .interspersef(function() return span(", "))
    )
    .concat([
      br(),
      span(["class" => "label"], msg.found)
    ])
    .concat(
      switch err.positionToString() {
        case None: [span(["class" => "eof"], " " + msg.endOfFile)];
        case Some(content): [br(), span(["class" => "got"], content)];
      }
    );
  }

  static var didInput = false;
  function onChange(text: String) {
    if(didInput) {
      props.dispatch(EvaluateExpression(text));
    } else {
      didInput = true;
      props.dispatch(Composite(EvaluateExpression(text), HideExpressionTooltip));
    }
  }
}

typedef SimulatorProps = {
  dispatch: Api,
  expr: Expression,
  displayTooltip: Bool
}
