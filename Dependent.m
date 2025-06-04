classdef Dependent < handle & matlab.mixin.indexing.RedefinesParen & matlab.mixin.indexing.RedefinesBrace

    properties (Access=private)
        ContainedArray
    end

    properties (Access=public)
        Parameters
        Label
        Log
    end

    properties (Dependent, Access=public)
        Dependency  
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
            %nbparams = ndims(ContainedArray);
            fields = fieldnames(args.Parameters);
            %             if ~(length(fields) == nbparams)
            %                 error('Wrong number of fields in argument Parameters');
            %             end
            for k = 1:length(fields)
                indep=args.Parameters.(fields{k});
                nbpts = size(ContainedArray,k);
                if ~(size(indep) == [1, size(ContainedArray,k)])
                    if ~(size(indep) == [size(ContainedArray,k),1])
                        indep=indep.';
                    end
                else
                    error("Parameter " + fields{k} + " must be row vectors with "+ nbpts + " elements");
                end
            end

            % Fill attributes
            obj.ContainedArray = ContainedArray;
            obj.Parameters = args.Parameters;
            obj.Label = args.Label;
            obj.Log = args.Log;
        end

        function value = get.Dependency(obj)
            value = fieldnames(obj.Parameters);
        end

        function s=dependent2struct(obj)
            s = struct([]);
            s(1).ContainedArray = obj.ContainedArray;
            s(1).Parameters = obj.Parameters;
            s(1).Label = obj.Label;
            s(1).Log = obj.Log;
        end

        function plot(obj)
            deps = obj.Dependency;
            if isscalar(deps)
                paramname = deps{1};
                plot(obj.Parameters.(paramname),obj.value);
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

        function jsonStr = jsonencode(obj, varargin)
            %s = struct("Name", obj.Name, "Age", obj.Age);
            s = struct(...
                "Parameters", obj.Parameters, ...
                "ContainedArray", obj.ContainedArray, ...
                "Label", obj.Label, ...
                "Log", obj.Log);
            jsonStr = jsonencode(s, varargin{:});
        end

    end

    methods(Static)

        function obj = jsondecode(jsonStr, varargin)

            jsonData = jsondecode(jsonStr, varargin{:});

            obj=Dependent(jsonData.ContainedArray, ...
                Parameters = jsonData.Parameters, ...
                Label = jsonData.Label, ...
                Log = jsonData.Log);
        end

        function obj=struct2dependent(s)
            obj=Dependent(s(1).ContainedArray, ...
                Parameters = s(1).Parameters, ...
                Label = s(1).Label, ...
                Log = s(1).Log);
        end
    end

    methods (Access=protected)

        %*** Parenthesis **************************************************
        function varargout = parenReference(obj, indexOp)
            
            indices_cellarray = indexOp(1).Indices;

            newobj = obj.new;
            newobj.ContainedArray = obj.ContainedArray(indices_cellarray{:}); % obj.ContainedArray = obj.ContainedArray.(indexOp(1));
            for k=1:length(indices_cellarray)
                if isnumeric(indices_cellarray{k}) %test if the indices are an array of numeric (else is the case of ':', where parameters must not be modified)
                    newobj.Parameters.(obj.Dependency{k})=obj.Parameters.(obj.Dependency{k})(indices_cellarray{k});
                end
            end

            if isscalar(indexOp)
                varargout{1} = newobj;
            else
                [varargout{1:nargout}] = newobj.(indexOp(2:end));
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
        function indices_cellarray = values2indices(obj, values_cellarray)
            indices_cellarray = cell(size(values_cellarray)); %preallocation
            for k1 = 1:length(values_cellarray)
                referencedvals = values_cellarray{k1};
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
                    indices_cellarray{k1}=referencedindices;
                else %(case of ':' in referencedvals)
                    indices_cellarray{k1} = referencedvals;
                end
            end
        end

        function varargout = braceReference(obj,indexOp)
            newobj = obj.new;
            indices_cellarray = obj.values2indices(indexOp(1).Indices);

            %Call parenReference code with the found indices
            if isscalar(indexOp)
                varargout{1} = newobj(indices_cellarray{:});
            else
                [varargout{1:nargout}] = newobj(indices_cellarray{:}).(indexOp(2:end)); %NON TESTE
            end
        end

        function obj = braceAssign(obj,indexOp,varargin)
            indices_cellarray = obj.values2indices(indexOp(1).Indices);

            %Call parenAssign code with the found indices
            if isscalar(indexOp)
                obj(indices_cellarray{:}) = varargin{1};
            else
                obj(indices_cellarray{:}).(indexOp(2:end)) = varargin{1:nargin};
            end

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
                out=Dependent(squeeze(obj.value), "Parameters", newParameters, "Label", obj.Label);
            end
        end

        function out=new(obj)
            newParameters=struct([]);
            knew=1;
            for kold=1:size(obj.Dependency,1)
                currentPARAM=obj.Parameters.(obj.Dependency{kold})(:).';
                newParameters(1).(obj.Dependency{kold})=currentPARAM;
                knew=knew+1;
            end
            out=Dependent(obj.value, "Parameters", newParameters, "Label", obj.Label);
        end

        function out=eval(obj, func)
            % EVAL applies the function fun to each element of the Dependent.
            newParameters=struct([]);
            knew=1;
            for kold=1:size(obj.Dependency,1)
                currentPARAM=obj.Parameters.(obj.Dependency{kold})(:).';
                newParameters(1).(obj.Dependency{kold})=currentPARAM;
                knew=knew+1;
            end
            out=Dependent(func(obj.value), "Parameters", newParameters, "Label", "");
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
            %the computation of the size is modified to take singleton
            %dimensions (now size can be 3x4x1x1)
            siz = size(obj.ContainedArray,varargin{:});
            modifiedsiz = ones(1, length(fieldnames(obj.Parameters)));
            modifiedsiz(1:length(siz))=siz;
            [varargout{1:nargout}] = modifiedsiz;
        end

        function obj = renameParameter(obj,oldparametername,newparametername)
            arguments
                obj 
                oldparametername 
                newparametername 
            end
            paramindex=find(strcmp(obj.Dependency,oldparametername),1);
            if ~isempty(paramindex)
                obj.Parameters = renameStructField(obj.Parameters,oldparametername,newparametername);
                obj.Dependency{paramindex}=newparametername;
            else
                error(oldparametername)
            end
        end

        function result=rdivide(DepL, DepR)
            %   nwR = nwL\nwT     left deembedding (T=T1\T2)
             
            if isa(DepL, 'Dependent') && isa(DepR, 'Dependent')
                newParameters=struct([]);
                knew=1;
                for kold=1:size(DepL.Dependency,1)
                    currentPARAM=DepL.Parameters.(DepL.Dependency{kold})(:).';
                    newParameters(1).(DepL.Dependency{kold})=currentPARAM;
                    knew=knew+1;
                end
                result=Dependent(DepL.value./DepR.value, "Parameters", newParameters, "Label", "");

            else
                error('rdivide not defined for these two types of networks');
            end
        end
    end

    methods (Static, Access=public)
        function obj = empty(args)
            % d = Dependent.empty(Parameters = struct("p1", [1, 2], "p2", [10, 20, 30]));
            arguments
                args.Parameters = struct([]);
                args.Label = "";
            end
            fnames = fieldnames(args.Parameters);
            n = length(fnames);
            sz = nan(1,n);
            for k = 1:n
                sz(k) = length(args.Parameters.(fnames{k}));
            end
            
            if n==1
                array = nan(sz(1),1);
            else
                array = nan(sz);
            end

            obj = Dependent(array, Parameters=args.Parameters, Label=args.Label);
        end
    end

    
end

