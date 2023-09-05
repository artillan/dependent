classdef Dependent < matlab.mixin.indexing.RedefinesParen & matlab.mixin.indexing.RedefinesBrace

    properties (Access=private)
        ContainedArray
    end

    properties (Access=public)
        Parameters
        Dependency
        Label
        Log
    end

    methods
        function obj=Dependent(ContainedArray, args) 
            % X = Dependent(VALUE, Parameters=struct('param1',PARAM1,'param2',PARAM2), ...)

            arguments
                ContainedArray  {mustBeNumeric}
                args.Parameters struct
                args.Label      (1,1) string = ""
                args.Log        (1,1) string = ""
            end

            % Validate Parameters struct
            fields = fieldnames(args.Parameters);
            nbparams = length(fields);
            %ndimensions = ndims(ContainedArray);
%             if ~(length(fields) == nbparams)
%                 error('Wrong number of fields in argument Parameters');
%             end
            for k = 1:length(fields)
                indep=args.Parameters.(fields{k});
                nbpts = size(ContainedArray,k);
                if ~(size(indep) == [1, size(ContainedArray,k)])
                    error("Parameter " + fields{k} + " must be row vectors with "+ nbpts + " elements");
                end
            end

            % Fill attributes
            obj.ContainedArray = ContainedArray;
            obj.Dependency = fields;
            obj.Parameters = args.Parameters;
            obj.Label = args.Label;
            obj.Log = args.Log;
        end

        function s=dependent2struct(obj)
            s = struct([]);
            s(1).ContainedArray = obj.ContainedArray;
            s(1).Parameters = obj.Parameters;
            s(1).Dependency = obj.Dependency;
            s(1).Label = obj.Label;
            s(1).Log = obj.Log;
        end
        
        function plot(obj)
            deps = obj.Dependency;
            if length(deps)==1
                paramname = deps{1};
                plot(obj.Parameters.paramname,obj.value);
                xlabel(paramname);
                ylabel(obj.Label);
            elseif length(deps)==2
                param1name = deps{1};
                param2name = deps{2};
                [X,Y] = meshgrid(obj.Parameters.(param1name), obj.Parameters.(param2name));
                Z=obj.value.';
                meshc(X,Y,Z);
                xlabel(param1name);
                ylabel(param2name);
                zlabel(obj.Label);
            else
                warning('No plot function defined for Dependents with more than 2 parameters')
            end

        end

    end

    methods(Static)
        function obj=struct2dependent(s)
            obj=Dependent(s(1).ContainedArray, ...
                Parameters = s(1).Parameters, ...
                Dependency = s(1).Dependency, ...
                Label = s(1).Label, ...
                Log = s(1).Log);
        end
    end

    methods (Access=protected)

        %*** Parenthesis **************************************************
        function varargout = parenReference(obj, indexOp)
            obj.ContainedArray = obj.ContainedArray.(indexOp(1));
            Indices = indexOp(1).Indices;
            
            for k=1:length(Indices)
                obj.Parameters.(obj.Dependency{k})=obj.Parameters.(obj.Dependency{k})(Indices{k});
            end
            if isscalar(indexOp)
                varargout{1} = obj;
            else
                [varargout{1:nargout}] = obj.(indexOp(2:end));
            end
        end

        function obj = parenAssign(obj,indexOp,varargin)

            % A REPRENDRE !!!!
            obj.ContainedArray.(indexOp(1))=varargin{1};


            % Code d'origine!!!
            %             % Ensure object instance is the first argument of call.
            %             if isempty(obj)
            %                 obj = varargin{1};
            %             end
            %             if isscalar(indexOp)
            %                 assert(nargin==3);
            %                 rhs = varargin{1};
            %                 obj.ContainedArray.(indexOp) = rhs.ContainedArray;
            %                 return;
            %             end
            %             [obj.(indexOp(2:end))] = varargin{:};
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

        %*** Braces *******************************************************
        function varargout = braceReference(obj,indexOp)
            referencedvals_cell = indexOp(1).Indices;
            referencedindices_cell = cell(size(referencedvals_cell)); %preallocation
            for k1 = 1:length(referencedvals_cell)
                referencedvals = referencedvals_cell{k1};
                if isnumeric(referencedvals)
                    %find the indices corresponding to the references values
                    parametername = obj.Dependency{k1};
                    parametervals = obj.Parameters.(parametername);
                    referencedindices=[];
                    for k2=1:length(referencedvals)
                        for k3=1:length(parametervals)
                            if abs(referencedvals(k2)-parametervals(k3))<=10*eps
                                referencedindices = [referencedindices, k3];
                            end
                        end
                    end
                    referencedindices_cell{k1}=referencedindices;
                else %(case of ':' in referencedvals)
                    referencedindices_cell{k1} = referencedvals;
                end
            end
            Indices=referencedindices_cell;

            obj.ContainedArray = obj.ContainedArray(referencedindices_cell{:});
            for k1=1:length(referencedindices_cell)
                if isnumeric(Indices{k1})
                    obj.Parameters.(obj.Dependency{k1})=obj.Parameters.(obj.Dependency{k1})(Indices{k1});
                else %(case of ':' in referencedvals)
                    obj.Parameters.(obj.Dependency{k1})=obj.Parameters.(obj.Dependency{k1})
                end
            end
            
            if isscalar(indexOp)
                varargout{1} = obj;
            else
                [varargout{1:nargout}] = obj.(indexOp(2:end));
            end


            %
            %             if isscalar(indexOp)
            %                 varargout{1} = obj.ContainedArray(referencedindices_cell{:});
            %             else
            %                 obj.ContainedArray = obj.ContainedArray(referencedindices_cell{:});
            %                 for k1=1:length(referencedindices_cell)
            %                     obj.Parameters.(obj.Dependency{k1})=obj.Parameters.(obj.Dependency{k1})(Indices{k1});
            %                 end
            %                 [varargout{1:nargout}] = obj.(indexOp(2:end));
            %             end
            
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

    end

    methods (Access=public)
        function out = value(obj)
            out = obj.ContainedArray;
        end

        function out=squeeze(obj)
            newParameters=struct([]);
            knew=1;
            for kold=1:size(obj.Dependency,1)
                currentPARAM=obj.Parameters.(obj.Dependency{kold})(:).';

                %if the parameter is not a singleton->copy it, 
                % otherwise ->squeeze it
                if length(currentPARAM)>=2
                    newParameters(1).(obj.Dependency{kold})=currentPARAM;
                    knew=knew+1;
                end
                out=Dependent(squeeze(obj.value), "Parameters", newParameters);
            end
        end

        function out=new(obj)
            newParameters=struct([]);
            knew=1;
            for kold=1:size(obj.Dependency,1)
                currentPARAM=obj.Parameters.(obj.Dependency{kold})(:).';
                newParameters(1).(obj.Dependency{kold})=currentPARAM;
                knew=knew+1;
                out=Dependent(obj.value, "Parameters", newParameters);
            end
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




