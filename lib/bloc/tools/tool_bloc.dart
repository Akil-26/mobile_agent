import 'package:bloc/bloc.dart';
import '../../models/tool_definitions.dart';
import '../../services/tools_service.dart';
import '../../services/tool_registry.dart';

part 'tool_event.dart';
part 'tool_state.dart';

class ToolBloc extends Cubit<ToolState> {
  ToolBloc() : super(ToolInitial());

  Future<void> loadAvailableTools() async {
    try {
      emit(ToolsLoaded(tools: ToolRegistry.allTools));
    } catch (e) {
      emit(ToolError(error: e.toString()));
    }
  }

  Future<void> executeToolCall(ToolCall toolCall) async {
    try {
      emit(ToolExecuting(toolName: toolCall.tool));

      final result = await ToolsService.executeTool(toolCall);

      emit(ToolExecuted(
        result: result,
        description: ToolsService.describeToolResult(result),
      ));
    } catch (e) {
      emit(ToolError(error: e.toString()));
    }
  }

  Future<void> requestToolConfirmation(
    ToolCall toolCall,
    ToolDefinition definition,
  ) async {
    emit(ToolConfirmationRequired(
      toolCall: toolCall,
      definition: definition,
    ));
  }

  Future<void> confirmAndExecute(ToolCall toolCall) async {
    await executeToolCall(toolCall);
  }

  void resetState() {
    emit(ToolInitial());
  }
}
