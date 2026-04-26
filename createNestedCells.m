function nestedCell = createNestedCells(data, sizes)
% CREATENESTEDCELLS Creates a nested cell array structure based on a size vector.
% 
%   nestedCell = createNestedCells(data, sizes)
%
%   Inputs:
%       data - The flat array of data (must be 1D, e.g., 1xN).
%       sizes - A 1xM array specifying the dimensions of the nested structure.

    % Base Case 1: If no more dimensions are left, the result is the data itself.
    if isempty(sizes)
        nestedCell = data;
        return;
    end

    % Get the size of the current dimension (N)
    current_dim_size = sizes(1);
    
    % Get the remaining sizes for the recursive call
    remaining_sizes = sizes(2:end);
    
    % Handle empty dimension (size 0)
    if current_dim_size == 0
        nestedCell = {};
        return;
    end
    
    % Calculate the number of elements (K) that will be bundled into *each* % subsequent cell at the next level of recursion.
    num_elements_per_slice = numel(data) / current_dim_size;
    
    % Preallocate the cell array for the current dimension (1 x N)
    nestedCell = cell(1, current_dim_size);

    % Recursive Step: Iterate through the current dimension
    for i = 1:current_dim_size
        
        % CRUCIAL for respecting element order: 
        % Calculate the start and end indices for the 'slice' of data 
        % belonging to the current cell element (i-th cell).
        start_idx = (i - 1) * num_elements_per_slice + 1;
        end_idx = i * num_elements_per_slice;
        
        % Extract the data slice sequentially from the input array.
        data_slice = data(start_idx:end_idx);
        
        % Recursive call to build the next level of nesting with the sequential slice.
        nestedCell{i} = createNestedCells(data_slice, remaining_sizes);
    end

end



% function nestedCell = createNestedCells(data, sizes)
% % CREATENESTEDCELLS Creates a nested cell array structure based on a size vector.
% % 
% %   nestedCell = createNestedCells(data, sizes)
% %
% %   Inputs:
% %       data - The flat array of data (e.g., a 1xN array).
% %       sizes - A 1xM array specifying the dimensions of the nested structure.
% 
%     % Base Case 1: If no more dimensions are left, the result is the data itself.
%     if isempty(sizes)
%         nestedCell = data;
%         return;
%     end
% 
%     % Get the size of the current dimension
%     current_dim_size = sizes(1);
% 
%     % Get the remaining sizes for the recursive call
%     remaining_sizes = sizes(2:end);
% 
%     % Handle empty dimension (size 0)
%     if current_dim_size == 0
%         nestedCell = {};
%         return;
%     end
% 
%     % Calculate the total number of elements that belong in one 'slice' 
%     % (i.e., the next level of nesting).
%     num_elements_per_slice = numel(data) / current_dim_size;
% 
%     % Preallocate the cell array for the current dimension
%     nestedCell = cell(1, current_dim_size);
% 
%     % Recursive Step: Iterate through the current dimension
%     for i = 1:current_dim_size
% 
%         % Calculate the start and end indices for the 'slice' of data 
%         % belonging to the current cell element.
%         start_idx = (i - 1) * num_elements_per_slice + 1;
%         end_idx = i * num_elements_per_slice;
% 
%         % Extract the data slice (assumes data is columnar/sequential)
%         data_slice = data(start_idx:end_idx);
% 
%         % Recursive call to build the next level of nesting
%         nestedCell{i} = createNestedCells(data_slice, remaining_sizes);
%     end
% 
% end