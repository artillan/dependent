classdef Dependent < matlab.mixin.indexing.RedefinesParen & matlab.mixin.indexing.RedefinesBrace

    properties (Access=private)
        ContainedArray
    end
    
    properties (Access=public)
        Parameters
        Dependency
        Label
    end
    
    methods
         function obj=Dependent(varargin)
            % X = dependent(VALUE,'param1',PARAM1,'param2',PARAM2,...)
            if nargin>=1 %at least one argument
                val = varargin{1};
                if isnumeric(val) %determine whether vlaue is numeric array
                    nbparams = length(size(val));
                    obj.ContainedArray = val;
                    if nargin == 1+2*nbparams
                        obj.Parameters = struct([]);
                        obj.Dependency = cell(1,nbparams);
                        for k = 1:nbparams
                            parametername = varargin{2*k};
                            obj.Dependency{k} = parametername;
                            indep = varargin{2*k+1};
                            indep = indep(:);
                            obj.Parameters(1).(parametername)=indep;
                        end
                    else
                        error('Wrong number of input arguments');
                    end
                else
                    error('Value must a numeric');
                end
            else
                error('At east one argument must passed');
            end
        end
    end

    methods (Access=protected)

        %*** Braces *******************************************************
        function varargout = braceReference(obj,indexOp)
            referencedvals_cell = indexOp(1).Indices;
            referencedindices_cell = cell(size(referencedvals_cell)); %preallocation
            for k = 1:length(referencedvals_cell)
                referencedvals = referencedvals_cell{k};
                if isnumeric(referencedvals)
                    %find the indices corresponding to the references values
                    parametername = obj.Dependency{k};
                    parametervals = obj.Parameters.(parametername);
                    [~,referencedindices] = intersect(parametervals, referencedvals,'stable');
                    referencedindices_cell{k} = referencedindices;
                else
                    %just copy the references values (case of ':')
                    referencedindices_cell{k} = referencedvals;
                end    
            end
            obj.ContainedArray = obj.ContainedArray(referencedindices_cell{:});
            if isscalar(indexOp)
                varargout{1} = obj.ContainedArray;
                return;
            end
            [varargout{1:nargout}] = obj.(indexOp(2:end));
        end

        function obj = braceAssign(obj,indexOp,varargin)
            % TODO
            %             if isscalar(indexOp)
            %                 [obj.Arrays.(indexOp)] = varargin{:};
            %                 return;
            %             end
            %             [obj.Arrays.(indexOp)] = varargin{:};
        end

        function n = braceListLength(obj,indexOp,ctx)
            if numel(indexOp) <= 2
                n = 1;
                return;
            end
            containedObj = obj.(indexOp(1:2));
            n = listLength(containedObj,indexOp(3:end),ctx);
        end

        %*** Parenthesis **************************************************
        function varargout = parenReference(obj, indexOp)
            obj.ContainedArray = obj.ContainedArray.(indexOp(1));
            if isscalar(indexOp)
                varargout{1} = obj.ContainedArray;
                return;
            end
            [varargout{1:nargout}] = obj.(indexOp(2:end));
        end

        function obj = parenAssign(obj,indexOp,varargin)
            % Ensure object instance is the first argument of call.
            if isempty(obj)
                obj = varargin{1};
            end
            if isscalar(indexOp)
                assert(nargin==3);
                rhs = varargin{1};
                obj.ContainedArray.(indexOp) = rhs.ContainedArray;
                return;
            end
            [obj.(indexOp(2:end))] = varargin{:};
        end

        function n = parenListLength(obj,indexOp,ctx)
            if numel(indexOp) <= 2
                n = 1;
                return;
            end
            containedObj = obj.(indexOp(1:2));
            n = listLength(containedObj,indexOp(3:end),ctx);
        end

        function obj = parenDelete(obj,indexOp)
            obj.ContainedArray.(indexOp) = [];
        end
    end

    methods (Access=public)
        function out = value(obj)
            out = obj.ContainedArray;
        end
        
        function out = sum(obj)
            out = sum(obj.ContainedArray,"all");
        end
        
        function out = cat(dim,varargin)
            numCatArrays = nargin-1;
            newArgs = cell(numCatArrays,1);
            for ix = 1:numCatArrays
                if isa(varargin{ix},'ArrayWithLabel')
                    newArgs{ix} = varargin{ix}.ContainedArray;
                else
                    newArgs{ix} = varargin{ix};
                end
            end
            out = ArrayWithLabel(cat(dim,newArgs{:}));
        end

        function varargout = size(obj,varargin)
            [varargout{1:nargout}] = size(obj.ContainedArray,varargin{:});
        end
    end

    methods (Static, Access=public)
        function obj = empty()
            obj = ArrayWithLabel([]);
        end
    end
end




